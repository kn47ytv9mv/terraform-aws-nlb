# terraform-aws-nlb

Terraform module for a Network Load Balancer. Target groups and
listeners are separate modules —
[`terraform-aws-nlb-target-group`](https://github.com/kn47ytv9mv/terraform-aws-nlb-target-group)
and
[`terraform-aws-nlb-listener`](https://github.com/kn47ytv9mv/terraform-aws-nlb-listener)
— since one load balancer can have several of each.

## Cost

A Network Load Balancer bills hourly for as long as it exists, plus a
per-hour charge based on Network Load Balancer Capacity Units
consumed. Both charges apply regardless of whether the load balancer
is actively serving traffic. See AWS's
[Elastic Load Balancing pricing](https://aws.amazon.com/elasticloadbalancing/pricing/)
page for current rates.

## Design

Genuinely separate from
[`terraform-aws-alb`](https://github.com/kn47ytv9mv/terraform-aws-alb),
not a shared module with a type flag — the two share the underlying
`aws_lb` resource type, but the arguments that actually matter differ
enough to warrant it: an NLB has no `drop_invalid_header_fields` (an
HTTP-layer concept, meaningless at TCP/UDP/TLS), and gets
`subnet_mapping` for a fixed Elastic IP or private IPv4 address per
availability zone, which an ALB does not support at all.

`subnet_ids` and `subnet_mapping` are mutually exclusive: `subnet_ids`
lets AWS assign each availability zone's IP automatically;
`subnet_mapping` pins a specific Elastic IP allocation or private
address per subnet instead, for a load balancer whose IP addresses
need to be known in advance (a firewall allow-list on the client side,
for instance). AWS requires at least two entries either way, in
different availability zones — enforced by a `validation` block that
only checks the count, the same honest limitation as `terraform-aws-alb`'s
equivalent check.

`enable_cross_zone_load_balancing` is a real cost and latency
trade-off here, unlike an Application Load Balancer's (which is always
cross-zone at no extra charge) — a Network Load Balancer bills
standard data transfer rates for cross-zone traffic.

### Logging

Supplying `access_logs_bucket` enables access logging automatically —
there is no separate switch to remember. Note that a network load
balancer only writes access logs for **TLS** listeners; a plain TCP or
UDP listener produces none regardless of this setting.

## Usage

```hcl
module "nlb" {
  source = "kn47ytv9mv/nlb/aws"

  subnet_ids         = module.private_subnets[*].id
  security_group_ids = [module.nlb_security_group.id]
}
```

Or directly from this repository, an internet-facing NLB with a fixed
Elastic IP per availability zone:

```hcl
module "nlb" {
  source = "github.com/kn47ytv9mv/terraform-aws-nlb"

  internal = false

  subnet_mapping = [
    { subnet_id = module.public_subnet_a.id, allocation_id = aws_eip.nlb_a.id },
    { subnet_id = module.public_subnet_b.id, allocation_id = aws_eip.nlb_b.id },
  ]
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.9 |
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| name | The name of the load balancer. If null, a unique name is generated. | `null` | no |
| internal | Whether the load balancer is internal (private) rather than internet-facing. | `true` | no |
| subnet_ids | IDs of the subnets to attach the load balancer to, one per availability zone, each getting an AWS-assigned IP. Mutually exclusive with subnet_mapping — exactly one is required. AWS requires at least two, in different availability zones. | `null` | no |
| subnet_mapping | Subnets to attach the load balancer to, with an explicit Elastic IP or private IPv4 address per subnet — for a fixed, known IP per availability zone instead of an AWS-assigned one. Mutually exclusive with subnet_ids — exactly one is required. AWS requires at least two entries, in different availability zones. | `null` | no |
| security_group_ids | IDs of the security groups to associate with the load balancer. If null, traffic is not filtered by a security group at the load balancer itself (matching AWS's own default for a Network Load Balancer). | `null` | no |
| enable_cross_zone_load_balancing | Whether traffic can be distributed to targets in every enabled availability zone, not just the one the request entered through. Unlike an Application Load Balancer, this is a genuine cost/latency trade-off for a Network Load Balancer, not a free default — cross-zone traffic bills at standard data transfer rates. If null, AWS's own default (true) applies. | `null` | no |
| ip_address_type | The type of IP addresses used by the load balancer's subnets ('ipv4' or 'dualstack'). If null, AWS's own default (ipv4) applies. | `null` | no |
| tags | A map of tags to assign to the load balancer. | `null` | no |
| access_logs_bucket | Name of an S3 bucket receiving access logs. Supplying a bucket enables logging automatically. A network load balancer only writes access logs for TLS listeners. | `null` | no |
| access_logs_prefix | Prefix for access log object keys, before the `AWSLogs/<account-id>/` path AWS adds. | `null` | no |
| access_logs_enabled | Whether access log delivery is active, for turning it off without unsetting the bucket. | `null` | no |

## Outputs

| Name | Description |
|---|---|
| id | The ID of the load balancer. |
| arn | The ARN of the load balancer. |
| zone_id | The Route 53 hosted zone ID of the load balancer, for alias records. |
| dns_name | The DNS name of the load balancer. |
| arn_suffix | The portion of the ARN CloudWatch uses as its `LoadBalancer` dimension. Feed this into `terraform-aws-monitoring-baseline` — the full ARN matches no metrics. |
| name | The name of the load balancer. |

## License

MIT — see [LICENSE.md](LICENSE.md).
