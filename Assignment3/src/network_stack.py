from aws_cdk import (
    aws_ec2 as ec2,
    Stack,
)
from constructs import Construct

class NetworkStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Create VPC
        self.vpc = ec2.Vpc(self, "MyVpc",
            # Use two availability zones
            max_azs=2,

            subnet_configuration=[
                # Public Subnets
                ec2.SubnetConfiguration(
                    name="PublicSubnet",
                    subnet_type=ec2.SubnetType.PUBLIC,
                    cidr_mask=24
                ),

                # Private Subnets
                ec2.SubnetConfiguration(
                    name="PrivateSubnet",
                    subnet_type=ec2.SubnetType.PRIVATE_WITH_NAT,
                    cidr_mask=24
                )
            ]
        )

        # Return the subnets
        self.public_subnets = [subnet.subnet_id for subnet in self.vpc.public_subnets]
        self.private_subnets = [subnet.subnet_id for subnet in self.vpc.private_subnets]
