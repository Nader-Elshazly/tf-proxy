data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

resource "aws_security_group" "proxies_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backends_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.proxies_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "proxies" {
  count                       = var.instance_count_proxies
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.proxy_instance_type
  subnet_id                   = element(var.public_subnets, count.index % length(var.public_subnets))
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.proxies_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-proxy-${count.index + 1}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install -y nginx1",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "cat <<'EOF' | sudo tee /etc/nginx/conf.d/reverse_proxy.conf",
      "server {",
      "  listen 80;",
      "  location / {",
      "    proxy_set_header Host $host;",
      "    proxy_set_header X-Real-IP $remote_addr;",
      "    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;",
      "    proxy_pass http://${var.internal_alb_dns};",
      "  }",
      "}",
      "EOF",
      "sudo systemctl reload nginx"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }
}

resource "aws_instance" "backends" {
  count                       = var.instance_count_backends
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.backend_instance_type
  subnet_id                   = element(var.private_subnets, count.index % length(var.private_subnets))
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.backends_sg.id]
  associate_public_ip_address = false

  tags = {
    Name = "${var.project_name}-backend-${count.index + 1}"
  }

  provisioner "file" {
    source      = "${path.module}/../../app-files/web-app"
    destination = "/home/ec2-user/webapp"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.private_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y python3",
      "sudo pip3 install flask",
      "sudo mkdir -p /opt/webapp",
      "sudo cp -r /home/ec2-user/webapp/* /opt/webapp/",
      "sudo chmod +x /opt/webapp/app.py",
      "nohup python3 /opt/webapp/app.py > /tmp/webapp.log 2>&1 &"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.private_ip
    }
	connection {
	  type        = "ssh"
	  user        = "ec2-user"
	  private_key = file(var.private_key_path)
	  bastion_host = aws_instance.proxies[0].public_ip
	}
	 
 }
}

resource "aws_lb_target_group" "internal_tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group_attachment" "backends_attach" {
  for_each         = { for idx, inst in aws_instance.backends : idx => inst }
  target_group_arn = var.internal_tg_arn != "" ? var.internal_tg_arn : aws_lb_target_group.internal_tg.arn
  target_id        = each.value.private_ip
  port             = 80
}
