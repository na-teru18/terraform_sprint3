# terraformのバージョン
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# 使用するプロバイダ情報
provider "aws" {
  region = "ap-northeast-1"
}

# シークレット管理
variable "sercret_password" {
  type        = string
  description = "RDS用のpassword"
  sensitive   = true
}

# VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block = "10.0.0.0/21"
  tags = {
    Name = "reservation-vpc"
  }
}

# Internet_Gateway
resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "reservation-ig"
  }
}

# Subnet
resource "aws_subnet" "terraform_public_subnet_1" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "web-subnet-01"
  }
}

resource "aws_subnet" "terraform_public_subnet_2" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "ap-northeast-1d"
  tags = {
    Name = "elb-subnet-01"
  }
}

resource "aws_subnet" "terraform_public_subnet_3" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "elb-subnet-02"
  }
}

resource "aws_subnet" "terraform_private_subnet_3" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1d"
  tags = {
    Name = "api-subnet-01"
  }
}

resource "aws_subnet" "terraform_private_subnet_4" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "api-subnet-02"
  }
}


resource "aws_subnet" "terraform_private_subnet_1" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1d"
  tags = {
    Name = "db-subnet-01"
  }
}

resource "aws_subnet" "terraform_private_subnet_2" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "db-subnet-02"
  }
}


# ルートテーブル
resource "aws_route_table" "terraform_public_web_routetable" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }

  route {
    cidr_block = "10.0.0.0/21"
    gateway_id = "local"
  }

  tags = {
    Name = "web-routetable"
  }
}

resource "aws_route_table" "terraform_public_elb_routetable" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }

  route {
    cidr_block = "10.0.0.0/21"
    gateway_id = "local"
  }

  tags = {
    Name = "elb-routetable"
  }
}

resource "aws_route_table" "terraform_private_api_routetable" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "10.0.0.0/21"
    gateway_id = "local"
  }

  tags = {
    Name = "api-routetable"
  }
}

resource "aws_route_table" "terraform_private_db_routetable" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "10.0.0.0/21"
    gateway_id = "local"
  }

  tags = {
    Name = "db-routetable"
  }
}


# ルートテーブルをサブネットに関連付けする
resource "aws_route_table_association" "web_sub_assc" {
  subnet_id      = aws_subnet.terraform_public_subnet_1.id
  route_table_id = aws_route_table.terraform_public_web_routetable.id
}

resource "aws_route_table_association" "elb_sub_assc_1" {
  subnet_id      = aws_subnet.terraform_public_subnet_2.id
  route_table_id = aws_route_table.terraform_public_elb_routetable.id
}

resource "aws_route_table_association" "elb_sub_assc_2" {
  subnet_id      = aws_subnet.terraform_public_subnet_3.id
  route_table_id = aws_route_table.terraform_public_elb_routetable.id
}

resource "aws_route_table_association" "api_sub_assc_1" {
  subnet_id      = aws_subnet.terraform_private_subnet_3.id
  route_table_id = aws_route_table.terraform_private_api_routetable.id
}

resource "aws_route_table_association" "api_sub_assc_2" {
  subnet_id      = aws_subnet.terraform_private_subnet_4.id
  route_table_id = aws_route_table.terraform_private_api_routetable.id
}

resource "aws_route_table_association" "db_sub_assc_1" {
  subnet_id      = aws_subnet.terraform_private_subnet_1.id
  route_table_id = aws_route_table.terraform_private_db_routetable.id
}

resource "aws_route_table_association" "db_sub_assc_2" {
  subnet_id      = aws_subnet.terraform_private_subnet_2.id
  route_table_id = aws_route_table.terraform_private_db_routetable.id
}

# セキュリティ・グループ
resource "aws_security_group" "terraform_ec2_sg" {
  name        = "ec2-sg"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

resource "aws_security_group" "terraform_alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# key-pair
# resource "aws_key_pair" "terraform_my_key_pair" {
#   key_name   = "Naemi_Keypair"
#   public_key = file("/Users/81909/.ssh/Naemi_Keypair.pub") # ローカルに保存しているキーペアのパス

# }

resource "aws_security_group" "terraform_api_sg" {
  name        = "api-sg"
  description = "Only allow alb_sg inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.terraform_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "api-sg"
  }
}

# EC2
resource "aws_instance" "terraform_web_server" {
  ami           = "ami-0d4aa492f133a3068"
  instance_type = "t2.micro"
  # key_name                    = aws_key_pair.terraform_my_key_pair.key_name
  security_groups             = [aws_security_group.terraform_ec2_sg.id]
  subnet_id                   = aws_subnet.terraform_public_subnet_1.id
  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash
dnf update -y
dnf install -y nginx
systemctl enable --now nginx
cat <<HTML > /usr/share/nginx/html/index.html
    <!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>API Test Example</title>
<link rel="stylesheet" href="styles/styles.css">
<style type="text/css">
#result {
  margin-top: 20px;
  padding: 10px;
  border: 1px solid #ccc;
  margin-bottom: 20px;
}
.button {
  background-color: #333;  /* 濃いグレー */
  color: white;            /* テキストを白色に */
  padding: 10px 20px;      /* 内側の余白 */
  border: none;            /* 枠線なし */
  border-radius: 5px;      /* 角の丸み */
  font-size: 16px;         /* フォントサイズ */
  cursor: pointer;         /* カーソルをポインタに */
  transition: background-color 0.3s ease; /* 背景色の変化を滑らかに */
}
.button:hover {
  background-color: #555;  /* ホバー時はやや明るいグレーに */
}
</style>
</head>
<body>
<div id="result"></div>
<button id="apiTestButton" class="button">API Test</button>
<button id="databaseTestButton" class="button">Database Test</button>

<script src="config.js"></script>
<script src="scripts/scripts.js"></script>
</body>
</html>
HTML
  EOF

  tags = {
    Name = "web-server-01"
  }
}

# resource "aws_instance" "terraform_api_server_1" {
#   ami           = "ami-0d4aa492f133a3068"
#   instance_type = "t2.micro"
#   # key_name                    = aws_key_pair.terraform_my_key_pair.key_name
#   security_groups             = [aws_security_group.terraform_api_sg.id]
#   subnet_id                   = aws_subnet.terraform_private_subnet_3.id
#   associate_public_ip_address = false
#   tags = {
#     Name = "api-server-01"
#   }
# }

# resource "aws_instance" "terraform_api_server_2" {
#   ami           = "ami-0d4aa492f133a3068"
#   instance_type = "t2.micro"
#   # key_name                    = aws_key_pair.terraform_my_key_pair.key_name
#   security_groups             = [aws_security_group.terraform_api_sg.id]
#   subnet_id                   = aws_subnet.terraform_private_subnet_4.id
#   associate_public_ip_address = false
#   tags = {
#     Name = "api-server-02"
#   }
# }

# Elastic IP
# resource "aws_eip" "terraform_eip" {
#   instance = aws_instance.terraform_api_server.id
#   domain   = "vpc"
#   tags = {
#     Name = "public_gip"
#   }
# }

# セキュリティ・グループ
resource "aws_security_group" "terraform_db_sg" {
  name        = "db-sg"
  description = "Only allow ec2_sg inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.terraform_ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

# DBサブネット・グループ
resource "aws_db_subnet_group" "terraform_db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.terraform_private_subnet_1.id, aws_subnet.terraform_private_subnet_2.id]

  tags = {
    Name = "db-subnet-group"
  }
}

# RDS
resource "aws_db_instance" "terraform_db" {
  identifier           = "db-server"
  allocated_storage    = 10
  db_name              = "dbserver"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = var.sercret_password
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.terraform_db_subnet_group.name
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.terraform_db_sg.id]
}

# ALB
resource "aws_lb" "terraform_alb" {
  name               = "api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terraform_alb_sg.id]
  subnets            = [aws_subnet.terraform_public_subnet_2.id, aws_subnet.terraform_public_subnet_3.id]
  ip_address_type    = "ipv4"

  tags = {
    Environment = "api-alb"
  }
}

# # ターゲット・グループのバックエンドサーバ
# locals {
#   api_server_ids = {
#     "api-ser-1" = aws_instance.terraform_api_server_1.id, "api-ser-2" = aws_instance.terraform_api_server_2.id
#   }
# }

# ターゲット・グループ
resource "aws_lb_target_group" "terraform_alb_target_group" {
  name     = "api-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform_vpc.id
  health_check {
    interval            = 10
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    timeout             = 6
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

# # バックエンド・サーバをターゲット・グループとして登録する
# resource "aws_lb_target_group_attachment" "terraform_target_group_attachment" {
#   for_each         = local.api_server_ids
#   target_group_arn = aws_lb_target_group.terraform_alb_target_group.arn
#   target_id        = each.value
#   port             = 80
# }

# リスナー
resource "aws_lb_listener" "terraform_alb_listener" {
  load_balancer_arn = aws_lb.terraform_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform_alb_target_group.arn
  }
}

# リスナー・ルール
resource "aws_lb_listener_rule" "myapp_listener_rule" {
  listener_arn = aws_lb_listener.terraform_alb_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform_alb_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# 起動テンプレートの作成
resource "aws_launch_template" "terraform_launch_template" {
  name          = "api-server-template"
  image_id      = "ami-0d4aa492f133a3068" # AMIのIDを指定
  instance_type = "t2.micro"
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.terraform_api_sg.id]
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "terraform_auto_scaling_group" {
  name                      = "api-autoscaling"
  max_size                  = 4 # 最大キャパシティ
  min_size                  = 2 # 最小キャパシティ
  desired_capacity          = 2 # 希望するキャパシティ
  health_check_grace_period = 300
  health_check_type         = "EC2"
  launch_template {
    id      = aws_launch_template.terraform_launch_template.id
    version = "$Latest"
  }
  vpc_zone_identifier = [aws_subnet.terraform_private_subnet_3.id, aws_subnet.terraform_private_subnet_4.id]
  target_group_arns   = [aws_lb_target_group.terraform_alb_target_group.arn]
}

# Autoscaling Policy
resource "aws_autoscaling_policy" "terraform_asg_policy" {
  name                   = "api-asg-policy"
  autoscaling_group_name = aws_autoscaling_group.terraform_auto_scaling_group.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# IAMグループ
resource "aws_iam_group" "terraform_server_management_group" {
  name = "server-management-group"
  path = "/"
}

resource "aws_iam_group" "terraform_database_management_group" {
  name = "database-management-group"
  path = "/"
}

resource "aws_iam_group" "terraform_user_management_group" {
  name = "user-management-group"
  path = "/"
}

# IAMグループ・ポリシー
resource "aws_iam_group_policy" "terraform_server_management_policy" {
  name  = "server-management-policy"
  group = aws_iam_group.terraform_server_management_group.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action" : "ec2:*",
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "elasticloadbalancing:*",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "cloudwatch:*",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "autoscaling:*",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "iam:CreateServiceLinkedRole",
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "iam:AWSServiceName" : [
              "autoscaling.amazonaws.com",
              "ec2scheduled.amazonaws.com",
              "elasticloadbalancing.amazonaws.com",
              "spot.amazonaws.com",
              "spotfleet.amazonaws.com",
              "transitgateway.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_group_policy" "terraform_database_management_policy" {
  name  = "database-management-policy"
  group = aws_iam_group.terraform_database_management_group.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "rds:*",
          "application-autoscaling:DeleteScalingPolicy",
          "application-autoscaling:DeregisterScalableTarget",
          "application-autoscaling:DescribeScalableTargets",
          "application-autoscaling:DescribeScalingActivities",
          "application-autoscaling:DescribeScalingPolicies",
          "application-autoscaling:PutScalingPolicy",
          "application-autoscaling:RegisterScalableTarget",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeCoipPools",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeLocalGatewayRouteTablePermissions",
          "ec2:DescribeLocalGatewayRouteTables",
          "ec2:DescribeLocalGatewayRouteTableVpcAssociations",
          "ec2:DescribeLocalGateways",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeVpcs",
          "ec2:GetCoipPoolUsage",
          "sns:ListSubscriptions",
          "sns:ListTopics",
          "sns:Publish",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "outposts:GetOutpostInstanceTypes",
          "devops-guru:GetResourceCollection"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "pi:*",
        "Resource" : [
          "arn:aws:pi:*:*:metrics/rds/*",
          "arn:aws:pi:*:*:perf-reports/rds/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "iam:CreateServiceLinkedRole",
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "iam:AWSServiceName" : [
              "rds.amazonaws.com",
              "rds.application-autoscaling.amazonaws.com"
            ]
          }
        }
      },
      {
        "Action" : [
          "devops-guru:SearchInsights",
          "devops-guru:ListAnomaliesForInsight"
        ],
        "Effect" : "Allow",
        "Resource" : "*",
        "Condition" : {
          "ForAllValues:StringEquals" : {
            "devops-guru:ServiceNames" : [
              "RDS"
            ]
          },
          "Null" : {
            "devops-guru:ServiceNames" : "false"
          }
        }
      }
    ]
  })
}

resource "aws_iam_group_policy" "terraform_user_management_policy" {
  name  = "user-management-policy"
  group = aws_iam_group.terraform_user_management_group.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:*",
          "organizations:DescribeAccount",
          "organizations:DescribeOrganization",
          "organizations:DescribeOrganizationalUnit",
          "organizations:DescribePolicy",
          "organizations:ListChildren",
          "organizations:ListParents",
          "organizations:ListPoliciesForTarget",
          "organizations:ListRoots",
          "organizations:ListPolicies",
          "organizations:ListTargetsForPolicy"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# IAMユーザー
resource "aws_iam_user" "terraform_manager" {
  name = "test-taro"
  path = "/"
}

resource "aws_iam_user" "terraform_application" {
  name = "test-jiro"
  path = "/"
}

resource "aws_iam_user" "terraform_db" {
  name = "test-saburo"
  path = "/"
}

resource "aws_iam_user" "terraform_tech_read" {
  name = "test-shiro"
  path = "/"
}

# IAMユーザーをIAMグループに追加する
resource "aws_iam_user_group_membership" "terraform_membership_taro" {
  user = aws_iam_user.terraform_manager.name

  groups = [
    aws_iam_group.terraform_user_management_group.name,
  ]
}


resource "aws_iam_user_group_membership" "terraform_membership_jiro" {
  user = aws_iam_user.terraform_application.name

  groups = [
    aws_iam_group.terraform_server_management_group.name,
  ]
}

resource "aws_iam_user_group_membership" "terraform_membership_saburo" {
  user = aws_iam_user.terraform_db.name

  groups = [
    aws_iam_group.terraform_database_management_group.name,
  ]
}

resource "aws_iam_user_group_membership" "terraform_membership_shiro" {
  user = aws_iam_user.terraform_tech_read.name

  groups = [
    aws_iam_group.terraform_server_management_group.name,
    aws_iam_group.terraform_database_management_group.name,
  ]
}
