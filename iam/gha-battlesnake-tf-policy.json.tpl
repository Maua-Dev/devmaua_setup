{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "LambdaScoped",
      "Effect": "Allow",
      "Action": ["lambda:*"],
      "Resource": [
        "arn:aws:lambda:*:${AWS_ACCOUNT_ID}:function:battlesnake-${REPO_NAME}-*",
        "arn:aws:lambda:*:${AWS_ACCOUNT_ID}:function:battlesnake-${REPO_NAME}-*:*"
      ]
    },
    {
      "Sid": "LambdaList",
      "Effect": "Allow",
      "Action": [
        "lambda:ListFunctions",
        "lambda:ListVersionsByFunction",
        "lambda:ListAliases",
        "lambda:GetAccountSettings",
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
        "arn:aws:logs:*:${AWS_ACCOUNT_ID}:log-group:/aws/lambda/battlesnake-${REPO_NAME}-*",
        "arn:aws:logs:*:${AWS_ACCOUNT_ID}:log-group:/aws/lambda/battlesnake-${REPO_NAME}-*:*"
      ]
    },
    {
      "Sid": "ApiGatewayManage",
      "Effect": "Allow",
      "Action": ["apigateway:*"],
      "Resource": [
        "arn:aws:apigateway:*::/restapis",
        "arn:aws:apigateway:*::/restapis/*",
        "arn:aws:apigateway:*::/tags/*",
        "arn:aws:apigateway:*::/account"
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
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/battlesnake-${REPO_NAME}-*"
      ]
    },
    {
      "Sid": "IamCreateRoleWithBoundary",
      "Effect": "Allow",
      "Action": ["iam:CreateRole"],
      "Resource": [
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/battlesnake-${REPO_NAME}-*"
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
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/battlesnake-${REPO_NAME}-*"
      ],
      "Condition": {
        "StringEquals": {
          "iam:PermissionsBoundary": "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/pb-battlesnake-participant"
        }
      }
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
      "Sid": "TfStateListFamilyBuckets",
      "Effect": "Allow",
      "Action": ["s3:ListBucket", "s3:GetBucketVersioning", "s3:GetBucketLocation", "s3:GetEncryptionConfiguration"],
      "Resource": [
        "arn:aws:s3:::battlesnake-*-template-terraform-state*"
      ],
      "Condition": {
        "StringLike": {
          "s3:prefix": [
            "app/${REPO_NAME}/*",
            "bootstrap*",
            "bootstrap/*",
            "bootstrap-javascript/*",
            "bootstrap-rust/*"
          ]
        }
      }
    },
    {
      "Sid": "TfStateObjectsRepoScoped",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetObjectVersion"
      ],
      "Resource": [
        "arn:aws:s3:::battlesnake-*-template-terraform-state*/app/${REPO_NAME}/*"
      ]
    },
    {
      "Sid": "TfBootstrapStateObjects",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetObjectVersion"
      ],
      "Resource": [
        "arn:aws:s3:::battlesnake-*-template-terraform-state*/bootstrap*",
        "arn:aws:s3:::battle-snake-bootstrap-state*/bootstrap*"
      ]
    },
    {
      "Sid": "TfBootstrapMetaBucket",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketVersioning",
        "s3:GetBucketLocation",
        "s3:GetEncryptionConfiguration",
        "s3:CreateBucket",
        "s3:PutBucketVersioning",
        "s3:PutBucketPublicAccessBlock",
        "s3:PutEncryptionConfiguration",
        "s3:GetBucketPublicAccessBlock"
      ],
      "Resource": [
        "arn:aws:s3:::battlesnake-*-template-terraform-state*",
        "arn:aws:s3:::battle-snake-bootstrap-state*"
      ]
    },
    {
      "Sid": "TfLocks",
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable",
        "dynamodb:CreateTable",
        "dynamodb:DescribeContinuousBackups",
        "dynamodb:DescribeTimeToLive",
        "dynamodb:ListTagsOfResource",
        "dynamodb:TagResource"
      ],
      "Resource": [
        "arn:aws:dynamodb:*:${AWS_ACCOUNT_ID}:table/battlesnake-*-template-terraform-locks*",
        "arn:aws:dynamodb:*:${AWS_ACCOUNT_ID}:table/battle-snake-bootstrap-state*"
      ]
    },
    {
      "Sid": "StsIdentity",
      "Effect": "Allow",
      "Action": ["sts:GetCallerIdentity"],
      "Resource": "*"
    }
  ]
}
