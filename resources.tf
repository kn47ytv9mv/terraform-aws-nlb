resource "random_uuid" "resource" {}

resource "aws_lb" "resource" {
  name     = coalesce(var.name, substr(random_uuid.resource.id, 0, 32))
  internal = var.internal

  load_balancer_type = "network"

  dynamic "access_logs" {
    for_each = var.access_logs_bucket[*]

    content {
      bucket  = access_logs.value
      prefix  = var.access_logs_prefix
      enabled = coalesce(var.access_logs_enabled, true)
    }
  }

  subnets         = var.subnet_ids
  security_groups = var.security_group_ids

  dynamic "subnet_mapping" {
    for_each = coalesce(var.subnet_mapping, [])

    content {
      subnet_id            = subnet_mapping.value.subnet_id
      allocation_id        = subnet_mapping.value.allocation_id
      private_ipv4_address = subnet_mapping.value.private_ipv4_address
      ipv6_address         = subnet_mapping.value.ipv6_address
    }
  }

  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  ip_address_type                  = var.ip_address_type

  tags = var.tags
}

output "id" {
  description = "The ID of the load balancer."
  value       = aws_lb.resource.id
}

output "name" {
  description = "The name of the load balancer."
  value       = aws_lb.resource.name
}

output "arn" {
  description = "The ARN of the load balancer."
  value       = aws_lb.resource.arn
}

output "arn_suffix" {
  description = "The portion of the ARN CloudWatch uses as its LoadBalancer dimension. Feed this into terraform-aws-monitoring-baseline's load_balancers — the full ARN matches no metrics."
  value       = aws_lb.resource.arn_suffix
}

output "zone_id" {
  description = "The Route 53 hosted zone ID of the load balancer, for alias records."
  value       = aws_lb.resource.zone_id
}

output "dns_name" {
  description = "The DNS name of the load balancer."
  value       = aws_lb.resource.dns_name
}
