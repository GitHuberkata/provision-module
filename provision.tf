terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.53.0"
    }
  }
}

module "networking" {
    source = "https://github.com/GitHuberkata/network-module/releases/tag/v1.0.2"
}

# Create aws server using previously created image/ami with installed nginx with Packer
resource "aws_instance" "web" {
  instance_type = "t2.micro"
  ami           = "ami-0d3cd2072dd2b3dbb"

  # Personal SSH keypair
  key_name = "petya-aws-pem"

# Our Security group to allow HTTP
  vpc_security_group_ids = ["${module.networking.custom1}"]

  # Launch the instance in private subnet
  subnet_id = module.networking.aws_private_subnet_id
  tags = {
    Name : "VM-to-test-NAT"
  }
  depends_on = [module.networking.eip_nat_gateway]
}
#The output will give an elb address to be accessed from browser
output "address" {
  value = aws_elb.web.dns_name
}

# Create elb 
resource "aws_elb" "web" {
  name = "petya-elb"

  subnets         = ["${module.networking.aws_private_subnet_id}","${module.networking.pub_subnet_id}"]
  security_groups = ["${module.networking.elb_security_group}"]
  instances       = ["${aws_instance.web.id}"]
  
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  depends_on = [module.networking.eip_nat_gateway]
}
