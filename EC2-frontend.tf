

#################### code deploy role ###############################
resource "aws_iam_role" "codedeployrole" {
  count = length(var.projectName)
  name  = "${var.projectName[count.index]}_codebuildRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "code-deploy-policy" {
  count       = length(var.projectName)
  name        = "${var.projectName[count.index]}_codebuildPolicy"
  description = "policy for code build"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:*",
                "ec2:*",
                "tag:GetResources",
                "sns:Publish",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:PutMetricAlarm",
                "elasticloadbalancing:*",
                "ecr:*",
                "cloudtrail:LookupEvents",
                "kms:*"

            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "replication.ecr.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codedeploy-attach" {
  count      = length(var.projectName)
  role       = aws_iam_role.codedeployrole[count.index].name
  policy_arn = aws_iam_policy.code-deploy-policy[count.index].arn
}



###################### code deploy  ##################


resource "aws_codedeploy_app" "codeDeployApp" {
  compute_platform = "Server"
  count            = length(var.projectName)
  name             = var.projectName[count.index]
}

resource "aws_codedeploy_deployment_group" "DeployAppGroup" {
  app_name              = aws_codedeploy_app.codeDeployApp[count.index].name
  count                 = length(var.projectName)
  deployment_group_name = var.projectName[count.index]
  service_role_arn      = aws_iam_role.codedeployrole[count.index].arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = var.ec2TagCodedeploy[count.index]
    }
  }
}
#############################################################################################################################33


############################################ pip role ###############
resource "aws_iam_role" "piprole" {
  count              = length(var.projectName)
  name               = "${var.projectName[count.index]}_pipelineRole"
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

resource "aws_iam_policy" "pip-policy" {
  count       = length(var.projectName)
  name        = "${var.projectName[count.index]}_pipelinePolicy"
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

resource "aws_iam_role_policy_attachment" "pip-policy-attach" {
  count      = length(var.projectName)
  role       = aws_iam_role.piprole[count.index].name
  policy_arn = aws_iam_policy.pip-policy[count.index].arn
}



############################ pipeline ######################################

resource "aws_codepipeline" "newpipeline" {
  count    = length(var.projectName)
  name     = var.projectName[count.index]
  role_arn = aws_iam_role.piprole[count.index].arn

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
        RepositoryName = "${var.codecommitRepoName[count.index]}"
        BranchName     = "${var.codecommitRepoBranch[count.index]}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ApplicationName : "${var.codedeployApplication[count.index]}"
        DeploymentGroupName : "${var.codedeployApplicationGROUP[count.index]}"
      }
    }
  }
}
