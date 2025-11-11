variable "project_name" {
  type    = string
  default = "tf-proxy"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name to use for SSH"
}

variable "private_key_path" {
  type        = string
  description = "Path on your machine to the private key (.pem) used by provisioners"
}

variable "ssh_allowed_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "instance_count_proxies" {
  type    = number
  default = 2
}

variable "instance_count_backends" {
  type    = number
  default = 2
}
