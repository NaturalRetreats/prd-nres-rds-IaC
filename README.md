# prd-nres-rds-IaC
This is terraform code to deploy a production environment for NRES
This repo is created in Dec 2024

The infrastructure is deployed in AWS us-east-1 region.
The code was first executed on 17th January 2025 and the infrastructure was deployed successfully.

## How to use this repo

1. Clone the repo
2. Run the terraform code
3. The infrastructure will be deployed in AWS us-east-1 region.

## Prerequisites

1. AWS account
2. AWS CLI
3. Terraform
4. VPC with ID `vpc-0a7fa0c2492fdae89`
5. Route Table with ID `rtb-07626cb1dcc0653d8`

## Usage

1. Clone the repository
2. Navigate to the directory
3. Run terraform init
4. Run terraform plan
5. Run terraform apply

## Terraform.tfvars
1. aws_access_key: AWS access key
2. aws_secret_key: AWS secret key