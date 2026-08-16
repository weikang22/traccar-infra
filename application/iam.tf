data "aws_iam_policy_document" "ec2_assume_role" { # creates iam trust policy to allow ec2 to assume the role
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "traccar" { # iam role to attach to ec2 instance
  name               = "${var.project_name}-${var.environment}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

data "aws_iam_policy_document" "read_traccarDB_secrets" { # creates inline permission policy to allow ec2 to read secrets from secrets manager
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      data.terraform_remote_state.persistent.outputs.database_secret_arn
    ]
  }
}

resource "aws_iam_role_policy" "read_traccarDB_secrets" { # attaches the inline permission policy to the ec2 role
  name   = "read-traccarDB-secrets"
  role   = aws_iam_role.traccar.id
  policy = data.aws_iam_policy_document.read_traccarDB_secrets.json
}

resource "aws_iam_instance_profile" "traccar" {
  name = "${var.project_name}-${var.environment}-ec2-instance-profile"
  role = aws_iam_role.traccar.name
}