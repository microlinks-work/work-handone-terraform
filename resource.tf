# key_creation

resource "tls_private_key" "bashion_generated_tls" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_bashion_key" {
  key_name   = "bashion_key_${var.environment}"
  public_key = tls_private_key.bashion_generated_tls.public_key_openssh
}

# Saving key locally
resource "local_file" "bashion_key" {
   content = "${tls_private_key.bashion_generated_tls.private_key_pem}"
    filename = var.bashion_key_saving_filename_with_path
    file_permission = "0400"
}

# Bashion Security Group Creation
resource "aws_security_group" "bashion_sg" {
  name        = "bashion-SG-${var.environment}"
  description = "Allow TLS inbound traffic for ssh"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "bashion_sg_${var.environment}"
  }
}

# bashion Creation
resource "aws_instance" "bashion" {
  ami           = var.image
  instance_type = var.i_type
  key_name      = aws_key_pair.generated_bashion_key.key_name
  vpc_security_group_ids = [ aws_security_group.bashion_sg.id ]
  subnet_id =  var.subnet_id
  associate_public_ip_address = true
  tags = {
     Name = "bashion-${var.environment}"
  }

}

resource "aws_eip" "bashion_eip" {
  instance = aws_instance.bashion.id
  vpc      = true
}
/*
resource "aws_acm_certificate" "cert" {
  domain_name       = "example.com"
  validation_method = "DNS"

  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_transfer_server" "sftp_transfer" {
  endpoint_type = "VPC"
/*
  endpoint_details {
    subnet_ids = var.bashion_subnet_id
    vpc_id     = var.vpc_id
  }
*/
 /* 
  protocols   = "SFTP" # , "FTPS"]
  #certificate = aws_acm_certificate.example.arn

  #identity_provider_type = "API_GATEWAY"
  #url                    = "${aws_api_gateway_deployment.example.invoke_url}${aws_api_gateway_resource.example.path}"
}
*/