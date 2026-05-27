provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "ConnectedArena"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
