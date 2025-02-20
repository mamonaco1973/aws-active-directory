resource "random_password" "admin_password" {
  length             = 24
  special            = true
  override_special   = "!@#$%"
}

resource "aws_secretsmanager_secret" "admin_secret" {
  name = "admin_ad_credentials"
  description =  "AD Admin Credentials"
   lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "admin_secret_version" {
  secret_id     = aws_secretsmanager_secret.admin_secret.id
  secret_string = jsonencode({
    username = "MCLOUD\\Admin"
    password = random_password.admin_password.result
  })
}

# Two American Names - John Smith, Emily Davis

resource "random_password" "jsmith_password" {
  length             = 24
  special            = true
  override_special   = "!@#$%"
}

resource "aws_secretsmanager_secret" "jsmith_secret" {
  name = "jsmith_ad_credentials"
  description =  "John Smith's AD Credentials"
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "jsmith_secret_version" {
  secret_id     = aws_secretsmanager_secret.jsmith_secret.id
  secret_string = jsonencode({
    username = "MCLOUD\\jsmith"
    password = random_password.jsmith_password.result
  })
}

resource "random_password" "edavis_password" {
  length             = 24
  special            = true
  override_special   = "!@#$%"
}

resource "aws_secretsmanager_secret" "edavis_secret" {
  name = "edavis_ad_credentials"
  description =  "Emily Davis's AD Credentials"
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "edavis_secret_version" {
  secret_id     = aws_secretsmanager_secret.edavis_secret.id
  secret_string = jsonencode({
    username = "MCLOUD\\edavis"
    password = random_password.edavis_password.result
  })
}

# To Indian Names - Raj Patel, Amit Kumar


resource "random_password" "rpatel_password" {
  length             = 24
  special            = true
  override_special   = "!@#$%"
}

resource "aws_secretsmanager_secret" "rpatel_secret" {
  name = "rpatel_ad_credentials"
  description =  "Raj Patel's AD Credentials"
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "rpatel_secret_version" {
  secret_id     = aws_secretsmanager_secret.rpatel_secret.id
  secret_string = jsonencode({
    username = "MCLOUD\\rpatel"
    password = random_password.rpatel_password.result
  })
}

resource "random_password" "akumar_password" {
  length             = 24
  special            = true
  override_special   = "!@#$%"
}

resource "aws_secretsmanager_secret" "akumar_secret" {
  name = "akumar_ad_credentials"
  description =  "Amit Kumar's AD Credentials"
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "akumar_secret_version" {
  secret_id     = aws_secretsmanager_secret.akumar_secret.id
  secret_string = jsonencode({
    username = "MCLOUD\\akumar"
    password = random_password.akumar_password.result
  })
}
