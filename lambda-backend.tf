################# build docker image with code commit ###########################

#################### code build role #################################
resource "aws_iam_role" "codeBuildrole" {
  count = length(var.backendprojectName)
  name  = "${var.backendprojectName[count.index]}_codebuildRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "code-build-policy" {
  count       = length(var.backendprojectName)
  name        = "${var.backendprojectName[count.index]}_codebuildPolicy"
  description = "policy for code build"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:*",
        "logs:*",
        "codebuild:*",
        "kms:*",
        "s3:*",
        "cloudformation:*",
        "lambda:*"

      ],
      "Effect": "Allow",
      "Resource": "*"
    },
        {
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": [
                "arn:aws:iam::700014156158:role/Cloud_Formation_Role"
            ]
        }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codebuild-attach" {
  count      = length(var.backendprojectName)
  role       = aws_iam_role.codeBuildrole[count.index].name
  policy_arn = aws_iam_policy.code-build-policy[count.index].arn
}



###################### code build ##################

resource "aws_codebuild_project" "codebuildIMG" {
  count         = length(var.backendprojectName)
  name          = var.backendprojectName[count.index]
  description   = "codebuild_project"
  service_role  = aws_iam_role.codeBuildrole[count.index].arn
  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = "true"

   
    environment_variable {
      name  = "deploymentBucket"
      value = var.deploybucketName
    }

    environment_variable {
      name  = "ENV"
      value = var.bucketFolderName
    }

  }

  # logs_config {
  #   cloudwatch_logs {
  #     group_name  = "${var.backendprojectName[count.index]}_log-group"
  #     stream_name = "${var.backendprojectName[count.index]}_log-stream"
  #   }
  # }

  source {
    type = "CODEPIPELINE"


    git_submodules_config {
      fetch_submodules = true
    }
  }
}


#############################################################################################################################33


############################################ pip role ###############
resource "aws_iam_role" "pipelinerole" {
  count              = length(var.backendprojectName)
  name               = "${var.backendprojectName[count.index]}_pipelineRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "pipeline-policy" {
  count       = length(var.backendprojectName)
  name        = "${var.backendprojectName[count.index]}_pipelinePolicy"
  description = "policy for pip"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject",
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild",
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment",
        "codedeploy:GetApplication",
        "codedeploy:GetApplicationRevision",
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:GetDeploymentConfig",
        "ecs:*",
        "ec2:*",
        "codecommit:*",
        "ecr:DescribeImages",
        "codestar-connections:UseConnection",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:ModifyRule"
        
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action":"iam:PassRole",
      "Resource":"*",
      "Condition":{
        "StringLike":{
          "iam:PassedToService":[
            "ec2.amazonaws.com",
            "ecs-tasks.amazonaws.com"
          ]
        }
      }
    },
  {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::${var.source_account_id}:role/*"
}
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "pipeline-policy-attach" {
  count      = length(var.backendprojectName)
  role       = aws_iam_role.pipelinerole[count.index].name
  policy_arn = aws_iam_policy.pipeline-policy[count.index].arn
}



############################ pipeline ######################################

resource "aws_codepipeline" "pipeline" {
  count    = length(var.backendprojectName)
  name     = var.backendprojectName[count.index]
  role_arn = aws_iam_role.pipelinerole[count.index].arn

  artifact_store {
    location = var.artifactbucketname
    type     = "S3"

    encryption_key {
      id   = "${var.kmsARN}"
      type = "KMS"
    }

  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]
      role_arn         = var.crossaccRoleARN

      configuration = {
        RepositoryName = "${var.backendcodecommitRepoName[count.index]}"
        BranchName     = "${var.codecommitRepoBranch[count.index]}"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuildIMG[count.index].name
      }
    }
  }
}
