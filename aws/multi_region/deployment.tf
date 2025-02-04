###########################################################
# Define SSH Keys to use for Deployment
# This key pair will be replicated across each region below
###########################################################
module "ssh_keys" {
  source = "./ssh_keys"

  ssh_authorized_keys = var.ssh_authorized_keys
  project_name        = var.project_name
}

###########################################################
# Define a primary region.
# This will house the Kasm Workspaces DB, and a set of
# agents/webapps that map to this region.
###########################################################
module "primary_region" {
  source                        = "./primary"
  aws_region                    = var.aws_primary_region
  zone_name                     = var.aws_primary_region
  vpc_subnet_cidr               = var.primary_vpc_subnet_cidr
  ec2_ami                       = var.primary_region_ec2_ami_id
  db_instance_type              = var.db_instance_type
  num_webapps                   = var.num_webapps
  num_cpx_nodes                 = var.num_cpx_nodes
  project_name                  = var.project_name
  kasm_build                    = var.kasm_build
  db_hdd_size_gb                = var.db_hdd_size_gb
  swap_size                     = var.swap_size
  database_password             = var.database_password
  redis_password                = var.redis_password
  user_password                 = var.user_password
  admin_password                = var.admin_password
  manager_token                 = var.manager_token
  service_registration_token    = var.service_registration_token
  aws_key_pair                  = module.primary_aws_key_pairs.aws_key_pair_name
  aws_domain_name               = var.aws_domain_name
  web_access_cidrs              = var.web_access_cidrs
  create_aws_ssm_iam_role       = var.create_aws_ssm_iam_role
  aws_ssm_iam_role_name         = var.aws_ssm_iam_role_name
  aws_ssm_instance_profile_name = var.aws_ssm_instance_profile_name
}

module "primary_region_webapps_and_agents" {
  source                          = "./webapps"
  faux_aws_region                 = var.aws_primary_region
  zone_name                       = var.aws_primary_region
  primary_aws_region              = var.aws_primary_region
  load_balancer_subnet_ids        = module.primary_region.lb_subnet_ids
  num_webapps                     = var.num_webapps
  num_agents                      = var.num_agents
  num_cpx_nodes                   = var.num_cpx_nodes
  ec2_ami                         = var.primary_region_ec2_ami_id
  swap_size                       = var.swap_size
  webapp_subnet_ids               = module.primary_region.webapp_subnet_ids
  webapp_security_group_id        = module.primary_region.webapp_security_group_id
  agent_subnet_id                 = module.primary_region.agent_subnet_id
  agent_security_group_id         = module.primary_region.agent_security_group_id
  cpx_subnet_id                   = module.primary_region.cpx_subnet_id
  cpx_security_group_id           = module.primary_region.cpx_security_group_id
  load_balancer_security_group_id = module.primary_region.lb_security_group_id
  webapp_instance_type            = var.webapp_instance_type
  webapp_hdd_size_gb              = var.webapp_hdd_size_gb
  agent_instance_type             = var.agent_instance_type
  agent_hdd_size_gb               = var.agent_hdd_size_gb
  cpx_instance_type               = var.cpx_instance_type
  cpx_hdd_size_gb                 = var.cpx_hdd_size_gb
  aws_domain_name                 = var.aws_domain_name
  project_name                    = var.project_name
  kasm_build                      = var.kasm_build
  database_password               = var.database_password
  redis_password                  = var.redis_password
  manager_token                   = var.manager_token
  service_registration_token      = var.service_registration_token
  aws_key_pair                    = module.primary_aws_key_pairs.aws_key_pair_name
  kasm_db_ip                      = module.primary_region.kasm_db_ip
  primary_vpc_id                  = module.primary_region.primary_vpc_id
  certificate_arn                 = module.primary_region.certificate_arn
  load_balancer_log_bucket        = module.primary_region.lb_log_bucket
  aws_ssm_instance_profile_name   = var.aws_ssm_instance_profile_name
}

module "primary_aws_key_pairs" {
  source              = "./aws_key_pairs"
  ssh_authorized_keys = module.ssh_keys.ssh_public_key
  project_name        = var.project_name
}

#####################################################################
#
# Add a webapp and agent module for each additional region desired.
#
#####################################################################
module "region2_webapps" {
  source                          = "./webapps"
  faux_aws_region                 = var.secondary_regions_settings.region2.agent_region
  zone_name                       = var.secondary_regions_settings.region2.agent_region
  primary_aws_region              = var.aws_primary_region
  load_balancer_subnet_ids        = module.primary_region.lb_subnet_ids
  num_webapps                     = var.num_webapps
  webapp_instance_type            = var.webapp_instance_type
  webapp_hdd_size_gb              = var.webapp_hdd_size_gb
  swap_size                       = var.swap_size
  aws_key_pair                    = module.region2_aws_key_pairs.aws_key_pair_name
  ec2_ami                         = var.primary_region_ec2_ami_id
  webapp_subnet_ids               = module.primary_region.webapp_subnet_ids
  webapp_security_group_id        = module.primary_region.webapp_security_group_id
  load_balancer_security_group_id = module.primary_region.lb_security_group_id
  aws_domain_name                 = var.aws_domain_name
  project_name                    = var.project_name
  kasm_build                      = var.kasm_build
  database_password               = var.database_password
  redis_password                  = var.redis_password
  manager_token                   = var.manager_token

  kasm_db_ip                    = module.primary_region.kasm_db_ip
  primary_vpc_id                = module.primary_region.primary_vpc_id
  certificate_arn               = module.primary_region.certificate_arn
  load_balancer_log_bucket      = module.primary_region.lb_log_bucket
  aws_ssm_instance_profile_name = var.aws_ssm_instance_profile_name
}

module "region2_agents" {
  source                        = "./agents"
  aws_region                    = var.secondary_regions_settings.region2.agent_region
  ec2_ami                       = var.secondary_regions_settings.region2.ec2_ami_id
  agent_vpc_cidr                = var.secondary_regions_settings.region2.agent_vpc_cidr
  management_region_nat_gateway = module.primary_region.nat_gateway_ip
  proxy_instance_type           = var.proxy_instance_type
  proxy_hdd_size_gb             = var.proxy_hdd_size_gb
  num_agents                    = var.num_agents
  agent_instance_type           = var.agent_instance_type
  agent_hdd_size_gb             = var.agent_hdd_size_gb
  num_cpx_nodes                 = var.num_cpx_nodes
  cpx_instance_type             = var.cpx_instance_type
  cpx_hdd_size_gb               = var.cpx_hdd_size_gb
  swap_size                     = var.swap_size
  aws_domain_name               = var.aws_domain_name
  project_name                  = var.project_name
  kasm_build                    = var.kasm_build
  aws_key_pair                  = module.region2_aws_key_pairs.aws_key_pair_name
  manager_token                 = var.manager_token
  service_registration_token    = var.service_registration_token
  aws_ssm_instance_profile_name = var.aws_ssm_instance_profile_name
  web_access_cidrs              = var.web_access_cidrs

  providers = {
    aws = aws.region2
  }
}

module "region2_aws_key_pairs" {
  source = "./aws_key_pairs"

  ssh_authorized_keys = module.ssh_keys.ssh_public_key
  project_name        = var.project_name

  providers = {
    aws = aws.region2
  }
}


#########################################################################
#
# Uncomment the below section and update the provider and the settings
# in the secondary_regions_settings variable in the terraform.tfvars
# file for your desired region.
#
#########################################################################
# module "region3_webapps" {
#   source                          = "./webapps"
#   faux_aws_region                 = var.secondary_regions_settings.region3.agent_region
#   zone_name                       = var.secondary_regions_settings.region3.agent_region
#   load_balancer_subnet_ids        = module.primary_region.lb_subnet_ids
#   primary_aws_region              = var.aws_primary_region
#   num_webapps                     = var.num_webapps
#   webapp_instance_type            = var.webapp_instance_type
#   webapp_hdd_size_gb              = var.webapp_hdd_size_gb
#   swap_size                       = var.swap_size
#   ec2_ami                         = var.primary_region_ec2_ami_id
#   webapp_subnet_ids               = module.primary_region.webapp_subnet_ids
#   webapp_security_group_id        = module.primary_region.webapp_security_group_id
#   load_balancer_security_group_id = module.primary_region.lb_security_group_id
#   aws_domain_name                 = var.aws_domain_name
#   project_name                    = var.project_name
#   kasm_build                      = var.kasm_build
#   database_password               = var.database_password
#   redis_password                  = var.redis_password
#   manager_token                   = var.manager_token
#   aws_key_pair                    = module.region2_aws_key_pairs
#   kasm_db_ip                      = module.primary_region.kasm_db_ip
#   primary_vpc_id                  = module.primary_region.primary_vpc_id
#   certificate_arn                 = module.primary_region.certificate_arn
#   load_balancer_log_bucket        = module.primary_region.lb_log_bucket
#   aws_ssm_instance_profile_name   = var.aws_ssm_instance_profile_name
# }

# module "region3_agents" {
#   source                        = "./agents"
#   aws_region                    = var.secondary_regions_settings.region3.agent_region
#   ec2_ami                       = var.secondary_regions_settings.region3.ec2_ami_id
#   agent_vpc_cidr                = var.secondary_regions_settings.region3.agent_vpc_cidr
#   load_balancer_log_bucket      = module.primary_region.lb_log_bucket
#   management_region_nat_gateway = module.primary_region.nat_gateway_ip
#   proxy_instance_type           = var.proxy_instance_type
#   proxy_hdd_size_gb             = var.proxy_hdd_size_gb
#   num_agents                    = var.num_agents
#   agent_instance_type           = var.agent_instance_type
#   agent_hdd_size_gb             = var.agent_hdd_size_gb
#   num_cpx_nodes                 = var.num_cpx_nodes
#   cpx_instance_type             = var.cpx_instance_type
#   cpx_hdd_size_gb               = var.cpx_hdd_size_gb
#   swap_size                     = var.swap_size
#   aws_domain_name               = var.aws_domain_name
#   project_name                  = var.project_name
#   kasm_build                    = var.kasm_build
#   aws_key_pair                  = var.aws_key_pair
#   manager_token                 = var.manager_token
#   service_registration_token    = var.service_registration_token
#   aws_ssm_instance_profile_name = var.aws_ssm_instance_profile_name
#   web_access_cidrs              = var.web_access_cidrs

#   providers = {
#     aws = aws.region3
#   }
# }

# module "region3_aws_key_pairs" {
#   source = "./aws_key_pairs"

#   ssh_authorized_keys = module.ssh_keys.ssh_public_key
#   project_name        = var.project_name

#   providers = {
#     aws = aws.region3
#   }
# }