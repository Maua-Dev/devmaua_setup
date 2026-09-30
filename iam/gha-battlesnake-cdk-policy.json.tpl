{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudFormationStackScoped",
      "Effect": "Allow",
      "Action": [
        "cloudformation:CreateStack",
        "cloudformation:UpdateStack",
        "cloudformation:DeleteStack",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackEvents",
        "cloudformation:DescribeStackResources",
        "cloudformation:DescribeStackResource",
        "cloudformation:GetTemplate",
        "cloudformation:CreateChangeSet",
        "cloudformation:DescribeChangeSet",
        "cloudformation:ExecuteChangeSet",
        "cloudformation:DeleteChangeSet",
        "cloudformation:GetTemplateSummary",
        "cloudformation:ListStackResources"
      ],
      "Resource": [
        "arn:aws:cloudformation:*:${AWS_ACCOUNT_ID}:stack/battlesnake-${REPO_SLUG}-*/*",
        "arn:aws:cloudformation:*:${AWS_ACCOUNT_ID}:stack/CDKToolkit/*"
      ]
    },
    {
      "Sid": "CloudFormationList",
      "Effect": "Allow",
      "Action": [
        "cloudformation:ListStacks",
        "cloudformation:ValidateTemplate"
      ],
      "Resource": "*"
    },
    {
      "Sid": "LambdaScoped",
      "Effect": "Allow",
      "Action": ["lambda:*"],
      "Resource": [
        "arn:aws:lambda:*:${AWS_ACCOUNT_ID}:function:battlesnake-${REPO_SLUG}-*",
        "arn:aws:lambda:*:${AWS_ACCOUNT_ID}:function:battlesnake-${REPO_SLUG}-*:*",
        "arn:aws:lambda:*:${AWS_ACCOUNT_ID}:layer:battlesnake-${REPO_SLUG}-*",
        "arn:aws:lambda:*:${AWS_ACCOUNT_ID}:layer:battlesnake-${REPO_SLUG}-*:*"
      ]
    },
    {
      "Sid": "LambdaEventSourceList",
      "Effect": "Allow",
      "Action": [
        "lambda:ListFunctions",
        "lambda:ListLayers",
        "lambda:ListEventSourceMappings",
        "lambda:GetAccountSettings",
        "lambda:CreateEventSourceMapping",
        "lambda:TagResource",
        "lambda:UntagResource",
        "lambda:ListTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "LogsScoped",
      "Effect": "Allow",
      "Action": ["logs:*"],
      "Resource": [
        "arn:aws:logs:*:${AWS_ACCOUNT_ID}:log-group:/aws/lambda/battlesnake-${REPO_SLUG}-*",
        "arn:aws:logs:*:${AWS_ACCOUNT_ID}:log-group:/aws/lambda/battlesnake-${REPO_SLUG}-*:*"
      ]
    },
    {
      "Sid": "CloudWatchAlarmsScoped",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:DescribeAlarmsForMetric",
        "cloudwatch:EnableAlarmActions",
        "cloudwatch:DisableAlarmActions",
        "cloudwatch:SetAlarmState",
        "cloudwatch:TagResource",
        "cloudwatch:UntagResource",
        "cloudwatch:ListTagsForResource"
      ],
      "Resource": [
        "arn:aws:cloudwatch:*:${AWS_ACCOUNT_ID}:alarm:battlesnake-${REPO_SLUG}-*"
      ]
    },
    {
      "Sid": "SnsSharedBattlesnake",
      "Effect": "Allow",
      "Action": [
        "sns:Publish",
        "sns:Subscribe",
        "sns:GetTopicAttributes",
        "sns:ListTopics"
      ],
      "Resource": [
        "arn:aws:sns:*:${AWS_ACCOUNT_ID}:sns-battlesnake"
      ]
    },
    {
      "Sid": "IamManagePrefixedRoles",
      "Effect": "Allow",
      "Action": [
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:UpdateAssumeRolePolicy",
        "iam:ListInstanceProfilesForRole"
      ],
      "Resource": [
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/battlesnake-${REPO_SLUG}-*",
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/battlesnake/battlesnake-${REPO_SLUG}-*"
      ]
    },
    {
      "Sid": "IamCreateRoleWithBoundary",
      "Effect": "Allow",
      "Action": ["iam:CreateRole"],
      "Resource": [
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/battlesnake-${REPO_SLUG}-*",
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/battlesnake/battlesnake-${REPO_SLUG}-*"
      ],
      "Condition": {
        "StringEquals": {
          "iam:PermissionsBoundary": "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/pb-battlesnake-participant"
        }
      }
    },
    {
      "Sid": "IamPassPrefixedRolesWithBoundary",
      "Effect": "Allow",
      "Action": ["iam:PassRole"],
      "Resource": [
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/battlesnake-${REPO_SLUG}-*",
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/battlesnake/battlesnake-${REPO_SLUG}-*"
      ],
      "Condition": {
        "StringEquals": {
          "iam:PermissionsBoundary": "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/pb-battlesnake-participant"
        }
      }
    },
    {
      "Sid": "IamPassBootstrapRoles",
      "Effect": "Allow",
      "Action": ["iam:PassRole", "iam:GetRole"],
      "Resource": [
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/cdk-hnb659fds-*"
      ]
    },
    {
      "Sid": "IamReadManagedPolicies",
      "Effect": "Allow",
      "Action": [
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicies"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CdkBootstrapAssets",
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": [
        "arn:aws:s3:::cdk-*-assets-${AWS_ACCOUNT_ID}-*",
        "arn:aws:s3:::cdk-*-assets-${AWS_ACCOUNT_ID}-*/*"
      ]
    },
    {
      "Sid": "SsmCdkBootstrap",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Resource": [
        "arn:aws:ssm:*:${AWS_ACCOUNT_ID}:parameter/cdk-bootstrap/*"
      ]
    },
    {
      "Sid": "EcrAuthForCdk",
      "Effect": "Allow",
      "Action": ["ecr:GetAuthorizationToken"],
      "Resource": "*"
    },
    {
      "Sid": "StsIdentity",
      "Effect": "Allow",
      "Action": ["sts:GetCallerIdentity"],
      "Resource": "*"
    }
  ]
}
