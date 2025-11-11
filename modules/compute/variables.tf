variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "key_name" { type = string }
variable "instance_count_proxies" { type = number }
variable "instance_count_backends" { type = number }
variable "proxy_instance_type" {
  type    = string
  default = "t3.micro"
}
variable "backend_instance_type" {
  type    = string
  default = "t3.micro"

}
variable "internal_tg_arn" { type = string }
variable "internal_alb_dns" { type = string }
variable "private_key_path" { type = string }
variable "ssh_allowed_cidr" {
  type    = string
  default = "0.0.0.0/0"
}
variable "aws_region" { type = string }
