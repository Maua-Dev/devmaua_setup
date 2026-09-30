{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:Maua-Dev/${REPO_NAME}:*",
            "repo:Maua-Dev@73619687/${REPO_NAME}:*"
          ]
        },
        "ForAllValues:StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:iss": "https://token.actions.githubusercontent.com"
        }
      }
    }
  ]
}
