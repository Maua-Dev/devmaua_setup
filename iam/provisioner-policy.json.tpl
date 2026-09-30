{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ManageBattlesnakeGhaRoles",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:UpdateAssumeRolePolicy",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:ListRoleTags",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:ListAttachedRolePolicies",
        "iam:UpdateRoleDescription",
        "iam:ListRoles"
      ],
      "Resource": [
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/gha-battlesnake-*"
      ]
    },
    {
      "Sid": "ListRolesAccount",
      "Effect": "Allow",
      "Action": [
        "iam:ListRoles",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicyVersions",
        "iam:GetOpenIDConnectProvider",
        "iam:ListOpenIDConnectProviders"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ReadBoundaryAndOidc",
      "Effect": "Allow",
      "Action": [
        "iam:GetRole",
        "iam:ListRoleTags"
      ],
      "Resource": [
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/gha-battlesnake-*"
      ]
    },
    {
      "Sid": "PassBoundaryOnCreate",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:PutRolePermissionsBoundary",
        "iam:DeleteRolePermissionsBoundary"
      ],
      "Resource": [
        "arn:aws:iam::${AWS_ACCOUNT_ID}:role/gha-battlesnake-*"
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
