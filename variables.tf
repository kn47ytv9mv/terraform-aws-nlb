variable "name" {
  default     = null
  description = "The name of the load balancer. If null, a unique name is generated."
}

variable "internal" {
  default     = true
  description = "Whether the load balancer is internal (private) rather than internet-facing."
}

variable "subnet_ids" {
  default     = null
  description = "IDs of the subnets to attach the load balancer to, one per availability zone, each getting an AWS-assigned IP. Mutually exclusive with subnet_mapping — exactly one is required. AWS requires at least two, in different availability zones."

  validation {
    condition     = var.subnet_ids == null || length(var.subnet_ids) >= 2
    error_message = "subnet_ids needs at least two subnets — AWS requires a Network Load Balancer to span at least two availability zones. This only checks the count, not that they are in different AZs."
  }
}

variable "subnet_mapping" {
  default     = null
  description = "Subnets to attach the load balancer to, with an explicit Elastic IP or private IPv4 address per subnet — for a fixed, known IP per availability zone instead of an AWS-assigned one. Mutually exclusive with subnet_ids — exactly one is required. AWS requires at least two entries, in different availability zones."
  type = list(object({
    subnet_id            = string
    allocation_id        = optional(string)
    private_ipv4_address = optional(string)
    ipv6_address         = optional(string)
  }))

  validation {
    condition     = (var.subnet_ids != null) != (var.subnet_mapping != null)
    error_message = "Exactly one of subnet_ids or subnet_mapping is required."
  }

  validation {
    condition     = var.subnet_mapping == null || length(var.subnet_mapping) >= 2
    error_message = "subnet_mapping needs at least two entries — AWS requires a Network Load Balancer to span at least two availability zones. This only checks the count, not that they are in different AZs."
  }
}

variable "security_group_ids" {
  default     = null
  description = "IDs of the security groups to associate with the load balancer. If null, traffic is not filtered by a security group at the load balancer itself (matching AWS's own default for a Network Load Balancer)."
}

variable "enable_cross_zone_load_balancing" {
  default     = null
  description = "Whether traffic can be distributed to targets in every enabled availability zone, not just the one the request entered through. Unlike an Application Load Balancer, this is a genuine cost/latency trade-off for a Network Load Balancer, not a free default — cross-zone traffic bills at standard data transfer rates. If null, AWS's own default (true) applies."
}

variable "ip_address_type" {
  default     = null
  description = "The type of IP addresses used by the load balancer's subnets ('ipv4' or 'dualstack'). If null, AWS's own default (ipv4) applies."
}

variable "access_logs_bucket" {
  default     = null
  description = "Name of an S3 bucket receiving access logs. Supplying a bucket enables logging automatically — there is no separate switch to remember, and access logging costs nothing beyond the S3 storage the logs occupy. A network load balancer only writes access logs for TLS listeners; a plain TCP listener produces none regardless of this setting. If null, no access logs are delivered."
}

variable "access_logs_prefix" {
  default     = null
  description = "Prefix for access log object keys, before the AWSLogs/<account-id>/ path AWS adds automatically."
}

variable "access_logs_enabled" {
  default     = null
  description = "Whether access log delivery is active, for turning it off without unsetting access_logs_bucket. If null, logging is enabled whenever access_logs_bucket is set."
}

variable "tags" {
  default     = null
  description = "A map of tags to assign to the load balancer."
}
