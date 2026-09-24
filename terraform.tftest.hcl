mock_provider "aws" {
}

run "rejects_neither_subnet_variant" {
  command = plan

  variables {}

  expect_failures = [var.subnet_mapping]
}

run "rejects_both_subnet_variants" {
  command = plan

  variables {
    subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    subnet_mapping = [
      { subnet_id = "subnet-0123456789abcdef0" },
      { subnet_id = "subnet-0123456789abcdef1" },
    ]
  }

  expect_failures = [var.subnet_mapping]
}

run "rejects_fewer_than_two_subnet_ids" {
  command = plan

  variables {
    subnet_ids = ["subnet-0123456789abcdef0"]
  }

  expect_failures = [var.subnet_ids]
}

run "rejects_fewer_than_two_subnet_mapping_entries" {
  command = plan

  variables {
    subnet_mapping = [
      { subnet_id = "subnet-0123456789abcdef0" },
    ]
  }

  expect_failures = [var.subnet_mapping]
}

run "default_config_creates_expected_resource" {
  command = apply

  variables {
    subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  }

  assert {
    condition     = aws_lb.resource.internal == true
    error_message = "internal should default to true (private by default)."
  }

  assert {
    condition     = aws_lb.resource.load_balancer_type == "network"
    error_message = "load_balancer_type should always be 'network'."
  }

  assert {
    condition     = length(aws_lb.resource.subnet_mapping) == 0
    error_message = "subnet_ids path should render no subnet_mapping blocks."
  }
}

run "subnet_mapping_renders_with_allocation_id" {
  command = apply

  variables {
    subnet_mapping = [
      { subnet_id = "subnet-0123456789abcdef0", allocation_id = "eipalloc-0123456789abcdef0" },
      { subnet_id = "subnet-0123456789abcdef1", allocation_id = "eipalloc-0123456789abcdef1" },
    ]
  }

  assert {
    condition     = length(aws_lb.resource.subnet_mapping) == 2
    error_message = "Two subnet_mapping entries should render exactly two subnet_mapping blocks."
  }

  assert {
    condition     = anytrue([for m in aws_lb.resource.subnet_mapping : m.allocation_id == "eipalloc-0123456789abcdef0"])
    error_message = "subnet_mapping.allocation_id should pass through unchanged."
  }
}

run "internal_false_for_internet_facing" {
  command = plan

  variables {
    subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    internal   = false
  }

  assert {
    condition     = aws_lb.resource.internal == false
    error_message = "internal should pass through unchanged."
  }
}

run "cross_zone_load_balancing_passes_through" {
  command = plan

  variables {
    subnet_ids                       = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    enable_cross_zone_load_balancing = false
  }

  assert {
    condition     = aws_lb.resource.enable_cross_zone_load_balancing == false
    error_message = "enable_cross_zone_load_balancing should pass through unchanged."
  }
}

run "no_access_logs_by_default" {
  command = plan

  variables {
    subnet_ids = ["subnet-1111", "subnet-2222"]
  }

  assert {
    condition     = length(aws_lb.resource.access_logs) == 0
    error_message = "Leaving access_logs_bucket unset should emit no access_logs block."
  }
}

run "supplying_a_bucket_enables_access_logs" {
  command = plan

  variables {
    subnet_ids         = ["subnet-1111", "subnet-2222"]
    access_logs_bucket = "lb-logs"
  }

  assert {
    condition     = aws_lb.resource.access_logs[0].enabled == true
    error_message = "Supplying a bucket should enable access logging automatically."
  }
}

run "readme_default_usage" {
  command = plan

  variables {
    subnet_ids         = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    security_group_ids = ["sg-0123456789abcdef0"]
  }
}

run "readme_static_ip_example" {
  command = plan

  variables {
    internal = false
    subnet_mapping = [
      { subnet_id = "subnet-0123456789abcdef0", allocation_id = "eipalloc-0123456789abcdef0" },
      { subnet_id = "subnet-0123456789abcdef1", allocation_id = "eipalloc-0123456789abcdef1" },
    ]
  }
}
