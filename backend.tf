terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "hw1-terraform-backend"
    key    = "tf-handson-2"
  }
}