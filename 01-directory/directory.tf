resource "aws_directory_service_directory" "ad_directory" {
  name        = "mikecloud.com"            # Change this to your desired AD domain name
  password    =  random_password.admin_password.result  
  edition     = "Standard"
  type        = "MicrosoftAD"
  short_name  = "mcloud"
  description = "mikecloud.com example for youtube channel"

  vpc_settings {
    vpc_id     = aws_vpc.ad-vpc.id
    subnet_ids = [
      aws_subnet.ad-subnet-1.id,
      aws_subnet.ad-subnet-2.id
    ]
  }

  tags = {
    Name = "mcloud"
  }
}

resource "aws_vpc_dhcp_options" "ad_dhcp_options" {
  domain_name         = "mikecloud.com"      # Replace with your AD domain name
  domain_name_servers = aws_directory_service_directory.ad_directory.dns_ip_addresses

  tags = {
    Name = "ad-dhcp-options"
  }
}

resource "aws_vpc_dhcp_options_association" "ad_dhcp_association" {
  vpc_id          = aws_vpc.ad-vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.ad_dhcp_options.id
}

