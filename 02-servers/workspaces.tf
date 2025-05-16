# -------------------------------
# Input Variable: Directory ID
# -------------------------------
variable "directory_id" {
  description = "The ID of the AWS Directory Service directory"  # Used to register an existing AWS Directory Service
  type        = string
}

# --------------------------------------------------
# Data Source: Lookup Directory Object by Directory ID
# --------------------------------------------------
data "aws_directory_service_directory" "mcloud" {
  directory_id = var.directory_id  # Pulls directory metadata based on provided ID
}

# ----------------------------------
# IAM Role for WorkSpaces Service
# ----------------------------------
resource "aws_iam_role" "workspaces_default" {
  name = "workspaces_DefaultRole"  # IAM Role name assigned to WorkSpaces

  # Trust policy: allows AWS WorkSpaces to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "workspaces.amazonaws.com"  # Trusted entity
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# -------------------------------------------------------------
# IAM Role Policy Attachment: WorkSpaces Core Service Access
# -------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "workspaces_service_access" {
  role       = aws_iam_role.workspaces_default.name  # Attach to the IAM role defined above
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesServiceAccess"  # Grants WorkSpaces service permissions
}

# --------------------------------------------------------------
# IAM Role Policy Attachment: WorkSpaces Self-Service Interface
# --------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "workspaces_self_service" {
  role       = aws_iam_role.workspaces_default.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesSelfServiceAccess"  # Enables user-facing management tools
}

# -------------------------------------------------
# Register Directory with the WorkSpaces Service
# -------------------------------------------------
resource "aws_workspaces_directory" "registered_directory" {
  directory_id = data.aws_directory_service_directory.mcloud.id  # Use existing directory lookup

  # Enable self-service features for users
  self_service_permissions {
    change_compute_type  = true    # Allow changing instance type (e.g., performance)
    increase_volume_size = true    # Allow increasing root/user disk sizes
    rebuild_workspace    = true    # Allow full rebuild from bundle
    restart_workspace    = true    # Allow restarting session
    switch_running_mode  = true    # Allow switching between "AlwaysOn" and "AutoStop"
  }

  # Allow access from all major supported platforms
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

  # Enforce IAM dependencies before registering
  depends_on = [
    aws_iam_role.workspaces_default,
    aws_iam_role_policy_attachment.workspaces_service_access,
    aws_iam_role_policy_attachment.workspaces_self_service
  ]
}

# ----------------------------------------------------
# Data Source: Windows Standard WorkSpaces Bundle
# ----------------------------------------------------
data "aws_workspaces_bundle" "windows_standard_bundle" {
  bundle_id = "wsb-93xk71ss4"  # Pre-defined Amazon bundle ID for Windows
}

# ---------------------------------------------------
# Data Source: Red Hat Standard WorkSpaces Bundle
# ---------------------------------------------------
data "aws_workspaces_bundle" "redhat_standard_bundle" {
  bundle_id = "wsb-8wthbqzhx"  # Pre-defined Amazon bundle ID for Red Hat Linux
}

# -------------------------------------------------------------
# Create a WorkSpace for Admin user with Windows Bundle
# -------------------------------------------------------------
resource "aws_workspaces_workspace" "admin_workspace_win" {
  directory_id = aws_workspaces_directory.registered_directory.directory_id  # Must reference the registered directory
  user_name    = "Admin"  # Login name to associate with this workspace
  bundle_id    = data.aws_workspaces_bundle.windows_standard_bundle.id  # Windows bundle for desktop

  # Define compute/storage settings for the instance
  workspace_properties {
    compute_type_name                         = "STANDARD"  # Mid-tier compute
    root_volume_size_gib                      = 80          # Root disk size in GiB
    user_volume_size_gib                      = 50          # User profile disk size in GiB
    running_mode                              = "AUTO_STOP" # Save cost by stopping when idle
    running_mode_auto_stop_timeout_in_minutes = 60          # Auto-stop after 60 minutes of inactivity
  }

  tags = {
    Name = "Admin WorkSpace"  # Tag used for management visibility
  }

  depends_on = [
    aws_workspaces_directory.registered_directory  # Ensure directory is registered before provisioning workspace
  ]
}

# ----------------------------------------------------------------
# (Optional) Create a WorkSpace for rpatel user using Red Hat OS
# ----------------------------------------------------------------
#resource "aws_workspaces_workspace" "rpatel_workspace_redhat" {
#  directory_id = aws_workspaces_directory.registered_directory.directory_id
#  user_name    = "rpatel"
#  bundle_id    = data.aws_workspaces_bundle.redhat_standard_bundle.id
#
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
#
#  depends_on = [
#    aws_workspaces_workspace.admin_workspace_win  # Create after Admin workspace, for dependency control
#  ]
#}
