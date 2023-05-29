resource "aws_ecr_repository" "my_ecr_repo" {
  name = "ecommerce-repo"
  force_delete = true
}

resource "aws_ecr_repository_policy" "my_ecr_repo_policy" {
  repository = aws_ecr_repository.my_ecr_repo.name

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "AllowPushPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
    }
  ]
}
EOF
}

data "aws_ecr_authorization_token" "auth_token" {}

resource "null_resource" "docker_push" {
  provisioner "local-exec" {
    command = <<EOF
    cd ..
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.my_ecr_repo.repository_url}
    docker build -t ${aws_ecr_repository.my_ecr_repo.repository_url}:latest .
    docker push ${aws_ecr_repository.my_ecr_repo.repository_url}:latest
    EOF
    }
}
