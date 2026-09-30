{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GitHubOidcBattlesnakeRepo",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:Maua-Dev/${REPO_NAME}:*"
        },
        "DateLessThan": {
          "aws:CurrentTime": "2026-10-12T23:59:59Z"
        }
      }
    }
  ]
}
