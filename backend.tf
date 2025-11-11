terraform {
  backend "s3" {
    bucket  = "mostafa-mmo"
    key     = "tf-finall-v4/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
