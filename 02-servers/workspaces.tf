

variable "directory_id" {
  description = "The ID of the AWS Directory Service directory"
  type        = string
}

data "aws_directory_service_directory" "mcloud" {
  directory_id = var.directory_id
}

resource "aws_iam_role" "workspaces_default" {
  name = "workspaces_DefaultRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "workspaces.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "workspaces_service_access" {
  role       = aws_iam_role.workspaces_default.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesServiceAccess"
}

resource "aws_iam_role_policy_attachment" "workspaces_self_service" {
  role       = aws_iam_role.workspaces_default.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesSelfServiceAccess"
}

resource "aws_workspaces_directory" "registered_directory" {
  directory_id = data.aws_directory_service_directory.mcloud.id

  self_service_permissions {
    change_compute_type  = true
    increase_volume_size = true
    rebuild_workspace    = true
    restart_workspace    = true
    switch_running_mode  = true
  }

  workspace_access_properties {
    device_type_android     = "ALLOW"
    device_type_chromeos    = "ALLOW"
    device_type_ios         = "ALLOW"
    device_type_linux       = "ALLOW"
    device_type_osx         = "ALLOW"
    device_type_web         = "ALLOW"
    device_type_windows     = "ALLOW"
    device_type_zeroclient  = "ALLOW"
  }

  depends_on = [
    aws_iam_role.workspaces_default,
    aws_iam_role_policy_attachment.workspaces_service_access,
    aws_iam_role_policy_attachment.workspaces_self_service
  ]

}

data "aws_workspaces_bundle" "windows_standard_bundle" {
  bundle_id = "wsb-93xk71ss4"
}


data "aws_workspaces_bundle" "redhat_standard_bundle" {
  bundle_id = "wsb-8wthbqzhx"
}


resource "aws_workspaces_workspace" "admin_workspace_win" {
  directory_id = aws_workspaces_directory.registered_directory.directory_id
  user_name    = "Admin"
  bundle_id    = data.aws_workspaces_bundle.windows_standard_bundle.id

  workspace_properties {
    compute_type_name                         = "STANDARD"
    root_volume_size_gib                      = 80
    user_volume_size_gib                      = 50
    running_mode                              = "AUTO_STOP"
    running_mode_auto_stop_timeout_in_minutes = 60
  }

  tags = {
    Name = "Admin WorkSpace"
  }

  depends_on = [
    aws_workspaces_directory.registered_directory
  ]
}

#resource "aws_workspaces_workspace" "rpatel_workspace_redhat" {
#  directory_id = aws_workspaces_directory.registered_directory.directory_id
#  user_name    = "rpatel"
#  bundle_id    = data.aws_workspaces_bundle.redhat_standard_bundle.id

#  workspace_properties {
#    compute_type_name                         = "STANDARD"
#    root_volume_size_gib                      = 80
#    user_volume_size_gib                      = 50
#    running_mode                              = "AUTO_STOP"
#    running_mode_auto_stop_timeout_in_minutes = 60
#  }
#
#  tags = {
#    Name = "rpatel workspace"
#  }

#  depends_on = [
#    aws_workspaces_workspace.admin_workspace_win
#  ]
#}

