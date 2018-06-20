variable "key_dir" {}
variable "region" {}

provider "aws" {
  region = "${var.region}"
}

resource "aws_s3_bucket" "ci" {
  bucket = "bosh-lite-pipeline"
  acl    = "private"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "bosh-pool"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 8, 1)}"
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "main" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = "${aws_subnet.main.id}"
  route_table_id = "${aws_route_table.main.id}"
}

resource "aws_security_group" "bosh" {
  name        = "bosh"
  description = "access to BOSH Lite v2"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6868
    to_port     = 6868
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 25555
    to_port     = 25555
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "udp"
    self      = true
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 80 and 443 allow us to hit a GoRouter if we deploy one
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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

output "internal_cidr" {
  value = "${aws_subnet.main.cidr_block}"
}

output "internal_gw" {
  value = "${cidrhost(aws_subnet.main.cidr_block, 1)}"
}

output "access_key_id" {
  value = "${aws_iam_access_key.bosh-pool.id}"
}

output "secret_access_key" {
  value = "${aws_iam_access_key.bosh-pool.secret}"
}

output "region" {
  value = "${var.region}"
}

output "az" {
  value = "${aws_subnet.main.availability_zone}"
}

output "default_key_name" {
  value = "${aws_key_pair.bosh-pool.key_name}"
}

output "default_security_groups" {
  value = "${format("%s", aws_security_group.bosh.name)}"
}

output "subnet_id" {
  value = "${aws_subnet.main.id}"
}
