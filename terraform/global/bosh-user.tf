variable "region" {}
variable "key_dir" {}

provider "aws" {
  region = "${var.region}"
}

resource "aws_iam_policy" "bosh-pool" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_user" "bosh-pool" {
  name = "bosh-pool"
}

resource "aws_iam_access_key" "bosh-pool" {
  user = "${aws_iam_user.bosh-pool.id}"
}

resource "aws_iam_user_policy_attachment" "bosh-pool" {
  user       = "${aws_iam_user.bosh-pool.id}"
  policy_arn = "${aws_iam_policy.bosh-pool.arn}"
}

resource "aws_key_pair" "bosh-pool" {
  key_name   = "bosh-pool"
  public_key = "${file(format("%s/id_rsa.pub", var.key_dir))}"
}

output "access_key_id" {
  value = "${aws_iam_access_key.bosh-pool.id}"
}

output "secret_access_key" {
  value = "${aws_iam_access_key.bosh-pool.secret}"
}

output "default_key_name" {
  value = "${aws_key_pair.bosh-pool.key_name}"
}
