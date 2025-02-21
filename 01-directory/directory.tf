# Create an AWS Managed Microsoft Active Directory (AD) instance
resource "aws_directory_service_directory" "ad_directory" {
  name        = "mikecloud.com"            # Fully Qualified Domain Name (FQDN) of the AD directory. Change this to your desired AD domain name.
  password    = random_password.admin_password.result  
                                           # Admin password for the directory, sourced from a secure random password resource.
  edition     = "Standard"                 # Choose the AD edition. Options: "Standard" (supports up to 5,000 users) or "Enterprise" (supports up to 100,000 users).
  type        = "MicrosoftAD"              # Specifies that this is a Microsoft Active Directory deployment.
  short_name  = "MCLOUD"                   # Shortened NetBIOS name of the domain.
  description = "mikecloud.com example for youtube channel"  
                                           # Descriptive metadata for the AD instance.

  # Define the Virtual Private Cloud (VPC) configuration for the AD directory
  vpc_settings {
    vpc_id     = aws_vpc.ad-vpc.id   # Associates the directory with a specific VPC.
    subnet_ids = [
      aws_subnet.ad-subnet-1.id,  # ID of the first subnet where the AD instance will be deployed.
      aws_subnet.ad-subnet-2.id   # ID of the second subnet to ensure high availability.
    ]
  }

  # Assign a tag to the AD directory for easier identification and resource management.
  tags = {
    Name = "mikecloud"  # Custom tag for easier identification in AWS Management Console and CLI.
  }
}

# Create a DHCP Options Set for the VPC to configure DNS settings for Active Directory
resource "aws_vpc_dhcp_options" "ad_dhcp_options" {
  domain_name         = "mikecloud.com"  # Specifies the domain name clients will use for DNS resolution within the VPC.
  domain_name_servers = aws_directory_service_directory.ad_directory.dns_ip_addresses  # Uses AD-provided DNS servers for domain name resolution.

  # Assign a tag to the DHCP options set for easier identification.
  tags = {
    Name = "ad-dhcp-options"  # Tag to identify this DHCP options set.
  }
}

# Associate the DHCP Options Set with the VPC to enforce Active Directory-specific DNS settings
resource "aws_vpc_dhcp_options_association" "ad_dhcp_association" {
  vpc_id          = aws_vpc.ad-vpc.id                         # VPC where the DHCP options set will be applied.
  dhcp_options_id = aws_vpc_dhcp_options.ad_dhcp_options.id   # The DHCP options set being associated with the VPC.
}
