variable "region" {}

provider "aws" {
  region = "${var.region}"
}

resource "aws_s3_bucket" "ci" {
  bucket = "bosh-lite-pipeline"
  acl    = "private"
}
