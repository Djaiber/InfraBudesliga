output "project_name" {
  value = aws_codebuild_project.lambda_image.name
}

output "project_arn" {
  value = aws_codebuild_project.lambda_image.arn
}

output "role_arn" {
  value = aws_iam_role.codebuild.arn
}
