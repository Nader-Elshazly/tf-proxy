terraform {
  backend "s3" {
    bucket  = "nader"
    key     = "tf-finall-v4/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
