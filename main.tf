module "dev_vpc" {
  source            = "git@github.com:minniemousek/my_TFmodules.git//vpc_module"
  custom_cidr_block = "10.0.0.0/22"
  custom_vpc_tag    = "hw4-vpc"
}

module "dev_subnets" {
  source = "git@github.com:minniemousek/my_TFmodules.git//subnet_module"

  for_each = {
    "public_1a" = ["10.0.0.0/24", "us-east-1a", "true"]
    public_1b   = ["10.0.1.0/24", "us-east-1b", "true"]
    private_1a  = ["10.0.2.0/24", "us-east-1a", "false"]
    private_1b  = ["10.0.3.0/24", "us-east-1b", "false"]
  }

  vpc_id                  = module.dev_vpc.vpc_id
  cidr_block              = each.value[0]
  avz                     = each.value[1]
  map_public_ip_on_launch = each.value[2]
  subnet_tag              = each.key
}

module "dev_igw" {
  source  = "git@github.com:minniemousek/my_TFmodules.git//igw_module"
  vpc_id  = module.dev_vpc.vpc_id
  igw_tag = "hw4-igw"
}

module "dev_natgw" {
  source    = "git@github.com:minniemousek/my_TFmodules.git//natgw_module"
  subnet_id = module.dev_subnets["public_1a"].sub_id
  natgw_tag = "hw4-natgw"
}

module "public_rtb" {
  source         = "git@github.com:minniemousek/my_TFmodules.git//rtb_module"
  vpc_id         = module.dev_vpc.vpc_id
  gateway_id     = module.dev_igw.igw_id
  nat_gateway_id = null
  subnets_ids    = [module.dev_subnets["public_1a"].sub_id, module.dev_subnets["public_1b"].sub_id]
}

module "private_rtb" {
  source         = "git@github.com:minniemousek/my_TFmodules.git//rtb_module"
  vpc_id         = module.dev_vpc.vpc_id
  gateway_id     = null
  nat_gateway_id = module.dev_natgw.natgw_id
  subnets_ids    = [module.dev_subnets["private_1a"].sub_id, module.dev_subnets["private_1b"].sub_id]
}

module "ec2_sec_group" {
  source      = "git@github.com:minniemousek/my_TFmodules.git//security_grp_module"
  name        = "hw4-ec2-sec-grp"
  description = "ec2_sec_grp"
  vpc_id      = module.dev_vpc.vpc_id
  sg_tag      = "hw4_ec2_sec_grp"
  sg_rules = {
    "Allow SSH"        = ["ingress", 22, 22, "TCP", "0.0.0.0/0"]
    "Allow HTTP"       = ["ingress", 80, 80, "TCP", module.alb_sec_group.sgrp_id]
    "Outbound traffic" = ["egress", 0, 0, "-1", "0.0.0.0/0"]
  }
}

module "alb_sec_group" {
  source      = "git@github.com:minniemousek/my_TFmodules.git//security_grp_module"
  name        = "hw4_alb-sgrp"
  description = "alb-sgrp"
  vpc_id      = module.dev_vpc.vpc_id
  sg_tag      = "hw4_alb_sgrp"
  sg_rules = {
    "Allow HTTP"       = ["ingress", 80, 80, "TCP", "0.0.0.0/0"]
    "Allow HTTPS"      = ["ingress", 443, 443, "TCP", "0.0.0.0/0"]
    "Outbound traffic" = ["egress", 0, 0, "-1", "0.0.0.0/0"]
  }
}
