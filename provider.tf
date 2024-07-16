provider "aws" {
  profile = "XXXX"
  region  = "us-east-1"
}



# ############ SAVING TF STATE FILE #########
# terraform {
#   backend "s3" {
#     bucket  = "my-bucket"
#     key     = "folder/terraform.tfstate"
#     region  = "us-east-1"
#     profile = "default"
#   }
# }
