provider "aws" {}


terraform {
  backend "s3" {
    bucket         = "dispatch-terraform"
    key            = "terraform.tfstate"
    region         = "eu-west-3"
    encrypt        = true
  }
}

provider "scaleway" {
  region  = "par1"
}

provider "external" {
  version = "1.0.0"
}

data "scaleway_image" "centos" {
  architecture = "arm64"
  name         = "CentOS 7.3"
}
