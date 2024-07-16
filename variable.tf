######### project name #######

variable "projectName" {
  type        = list(string)
  description = "project name for the setup"
  default     = ["laravel_frontend"]
}


########## pipeline variables #######


## s3
variable "artifactbucketname" {
  type        = string
  description = "name of artifact bucket for pipeline to put code on s3 and use for pipeline"
  default     = "codepipeline-us-east-1-XXX"
}

variable "codecommitRepoName" {
  type        = list(string)
  description = "name of code commit repo for pipeline source"
  default     = ["laravel_frontend"]
}


variable "codecommitRepoBranch" {
  type        = list(string)
  description = "name of code commit repo Branch for pipeline source"
  default     = ["production"]
}


variable "codedeployApplication" {
  type        = list(string)
  description = "name of code deploy application for pipeline"
  default     = ["laravel_frontend"]
}

variable "codedeployApplicationGROUP" {
  type        = list(string)
  description = "name of code deploy application group for pipeline"
  default     = ["laravel_frontend"]
}

variable "ec2TagCodedeploy" {
  type        = list(string)
  description = "name of ec2 for code deploy application group"
  default     = ["example-server"]
}


########## backend ##########


######## ECR ###############

# variable "ECRrepoName" {
#   type        = list(string)
#   description = "ecr repo name to store build img"
#   default     = ["laravel_backend"]
# }


########## backend ##########

######### project name #######

variable "backendprojectName" {
  type        = list(string)
  description = "project name for the setup"
  default     = ["laravel_backend"]
}

variable "backendcodecommitRepoName" {
  type        = list(string)
  description = "name of code commit repo for pipeline source"
  default     = ["laravel_backend"]
}

variable "deploybucketName" {
  type        = string
  description = "s3 bucket name for codebuild environment variable(buildspec)"
  default     = "deploymentbucket"
}

variable "bucketFolderName" {
  type        = string
  description = "s3 bucket folder name for codebuild environment variable(buildspec)"
  default     = "backend"
}


variable "VPCid" {
  type        = string
  description = "vpc id for sg"
  default     = "vpc-08d01303XXXXX"

}

variable "backendSGname" {
  type        = string
  description = "sg for backend properties yml file"
  default     = "laravel_backend_prd"

}

############# cross acc ###

variable "crossaccRoleARN" {
  type        = string
  description = "Role arn for cross acc pipeline"
  default     = "arn:aws:iam::12345699376:role/Crossaccountprod"
}

variable "source_account_id" {
  type        = string
  description = "source account id for cross acc pipeline role"
  default     = "123456789"

}

variable "kmsARN" {
  type        = string
  description = "KMS key ARN for cross acc pipeline s3"
  default     = "arn:aws:kms:us-east-1:1234567:key/XXXXXXXXXXXXX-YYYYYYYY"

}

