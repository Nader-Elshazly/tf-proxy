output "proxies_public_ips" { value = [for p in aws_instance.proxies : p.public_ip] }
output "backends_private_ips" { value = [for b in aws_instance.backends : b.private_ip] }
