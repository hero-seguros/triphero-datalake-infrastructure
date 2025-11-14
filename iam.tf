# IAM Role for Debezium (MSK and S3 access)
data "aws_iam_policy_document" "debezium_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.eks.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:debezium:debezium-connect"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "debezium" {
  name               = "${var.project_name}-${var.environment}-debezium"
  assume_role_policy = data.aws_iam_policy_document.debezium_assume_role.json

  tags = {
    Name        = "${var.project_name}-${var.environment}-debezium"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# IAM Policy for MSK access
data "aws_iam_policy_document" "debezium_msk" {
  statement {
    effect = "Allow"
    actions = [
      "kafka-cluster:Connect",
      "kafka-cluster:AlterCluster",
      "kafka-cluster:DescribeCluster"
    ]
    resources = [aws_msk_cluster.main.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "kafka-cluster:*Topic*",
      "kafka-cluster:WriteData",
      "kafka-cluster:ReadData"
    ]
    resources = ["${aws_msk_cluster.main.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kafka-cluster:AlterGroup",
      "kafka-cluster:DescribeGroup"
    ]
    resources = ["${aws_msk_cluster.main.arn}/*"]
  }
}

resource "aws_iam_policy" "debezium_msk" {
  name        = "${var.project_name}-${var.environment}-debezium-msk"
  description = "Policy for Debezium to access MSK cluster"
  policy      = data.aws_iam_policy_document.debezium_msk.json
}

resource "aws_iam_role_policy_attachment" "debezium_msk" {
  role       = aws_iam_role.debezium.name
  policy_arn = aws_iam_policy.debezium_msk.arn
}

# IAM Policy for Secrets Manager (database credentials)
data "aws_iam_policy_document" "debezium_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.project_name}/${var.environment}/database/*"]
  }
}

resource "aws_iam_policy" "debezium_secrets" {
  name        = "${var.project_name}-${var.environment}-debezium-secrets"
  description = "Policy for Debezium to access database credentials in Secrets Manager"
  policy      = data.aws_iam_policy_document.debezium_secrets.json
}

resource "aws_iam_role_policy_attachment" "debezium_secrets" {
  role       = aws_iam_role.debezium.name
  policy_arn = aws_iam_policy.debezium_secrets.arn
}
