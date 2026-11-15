
aws_region      = "ap-south-1"
cluster_name    = "jerney"
cluster_version = "1.37"

vpc_cidr = "10.0.0.0/16"

# Replace with your actual public IP address
# Example: ["123.45.67.89/32"]
cluster_endpoint_public_access_cidrs = [
  "212.104.231.72/32"
]

# EC2 worker node configuration
node_instance_types = ["c7i-flex.large"]

node_min_size     = 2
node_max_size     = 4
node_desired_size = 2
