# Creating an ECR Repository
resource "aws_ecr_repository" "aws-ecommerce-ecr-repo" {
  name = "aws-ecommerce-ecr-repo" 
  force_delete = true # allowing to delete the repository even if it contains an image
}

# Creating an ECS cluster
resource "aws_ecs_cluster" "aws-ecommerce-cluster" {
  name = "aws-ecommerce-cluster" 
}


# Creating the task definition
resource "aws_ecs_task_definition" "aws-ecommerce-task" {
  family                   = "aws-ecommerce-task" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "aws-ecommerce-container",
      "image": "${aws_ecr_repository.aws-ecommerce-ecr-repo.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our task requires
  cpu                      = 256         # Specifying the CPU our task requires
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn # Stating Amazon Resource Name (ARN) of the execution role
}


# Creating the service
resource "aws_ecs_service" "aws-ecommerce-service" {
  name            = "aws-ecommerce-service"                        
  cluster         = aws_ecs_cluster.aws-ecommerce-cluster.id       # Referencing our created Cluster
  task_definition = aws_ecs_task_definition.aws-ecommerce-task.arn # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 3 # Setting the number of containers we want deployed to 3

  load_balancer {
    target_group_arn = aws_lb_target_group.aws-ecommerce-target_group.arn # Referencing our target group
    container_name   = "aws-ecommerce-container"
    container_port   = 3000 # Specifying the container port
  }

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}", "${aws_default_subnet.default_subnet_c.id}"]
    assign_public_ip = true                                                # Providing our containers with public IPs
    security_groups  = ["${aws_security_group.aws-ecommerce-service_security_group.id}"] # Setting the security group
  }
}

# Creating a security group for the service
resource "aws_security_group" "aws-ecommerce-service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = ["${aws_security_group.aws-ecommerce-lb_security_group.id}"]
  }

  egress {
    from_port   = 0             # Allowing any incoming port
    to_port     = 0             # Allowing any outgoing port
    protocol    = "-1"          # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

