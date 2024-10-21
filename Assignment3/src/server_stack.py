from aws_cdk import (
    aws_ec2 as ec2,
    aws_rds as rds,
    Stack,
)
from constructs import Construct

class ServerStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, vpc, public_subnets, private_subnets, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Create SG for web servers
        web_sg = ec2.SecurityGroup(self, "WebSecurityGroup", vpc=vpc, allow_all_outbound=True)
        web_sg.add_ingress_rule(ec2.Peer.any_ipv4(), ec2.Port.tcp(80), "Allow HTTP access")

        # Launch one web server in each public subnets
        for subnet in public_subnets:
            ec2.Instance(self, f"WebServer{subnet}",
                instance_type=ec2.InstanceType.of(
                    ec2.InstanceClass.BURSTABLE2, ec2.InstanceSize.MICRO),
                machine_image=ec2.MachineImage.latest_amazon_linux(),
                vpc=vpc,
                vpc_subnets=ec2.SubnetSelection(subnets=[subnet]),
                security_group=web_sg
            )

        # RDS instance with MySQL engine with all private subnets as its subnet group
        rds_sg = ec2.SecurityGroup(self, "RDSSecurityGroup", vpc=vpc, allow_all_outbound=True)
        rds_sg.add_ingress_rule(web_sg, ec2.Port.tcp(3306), "Allow MySQL engine access from web servers")

        rds.DatabaseInstance(self, "MyRDS",
            engine=rds.DatabaseInstanceEngine.mysql(
                version=rds.MysqlEngineVersion.VER_8_0_19
            ),
            vpc=vpc,
            vpc_subnets=ec2.SubnetSelection(subnets=[subnet for subnet in private_subnets]),
            security_groups=[rds_sg],
            instance_type=ec2.InstanceType.of(
                ec2.InstanceClass.BURSTABLE2, ec2.InstanceSize.MICRO),
            multi_az=True,
            allocated_storage=20,
            max_allocated_storage=100,
            publicly_accessible=False,
        )
