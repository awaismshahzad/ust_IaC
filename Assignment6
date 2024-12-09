import * as cdk from 'aws-cdk-lib';
import { Stack, StackProps } from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as elb from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as iam from 'aws-cdk-lib/aws-iam';

export class CloudFormationToCdkStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    // Parameters
    const instanceType = new cdk.CfnParameter(this, 'InstanceType', {
      type: 'String',
      default: 't2.micro',
      allowedValues: ['t2.micro', 't2.small'],
      description: 'Server instance type',
    });

    const keyPair = new cdk.CfnParameter(this, 'KeyPair', {
      type: 'AWS::EC2::KeyPair::KeyName',
      description: 'Name of existing EC2 KeyPair for SSH access',
    });

    const yourIp = new cdk.CfnParameter(this, 'YourIp', {
      type: 'String',
      description: 'Your public IP address in CIDR',
    });

    // VPC
    const vpc = new ec2.Vpc(this, 'EngineeringVpc', {
      cidr: '10.0.0.0/18',
      maxAzs: 2,
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'PublicSubnet1',
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          cidrMask: 24,
          name: 'PublicSubnet2',
          subnetType: ec2.SubnetType.PUBLIC,
        },
      ],
    });

    // Security Group
    const securityGroup = new ec2.SecurityGroup(this, 'WebserversSG', {
      vpc,
      description: 'Allow HTTP & SSH traffic',
      allowAllOutbound: true,
    });

    securityGroup.addIngressRule(ec2.Peer.ipv4(yourIp.valueAsString), ec2.Port.tcp(22), 'Allow SSH');
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(80), 'Allow HTTP');

    // EC2 Instances
    const web1 = new ec2.Instance(this, 'Web1', {
      vpc,
      instanceType: new ec2.InstanceType(instanceType.valueAsString),
      machineImage: ec2.MachineImage.genericLinux({
        'us-east-1': 'ami-01cc34ab2709337aa',
      }),
      keyName: keyPair.valueAsString,
      securityGroup,
      vpcSubnets: { subnets: [vpc.publicSubnets[0]] },
    });

    web1.addUserData(
      `#!/bin/bash
      yum update -y
      yum install -y git httpd php
      service httpd start
      chkconfig httpd on
      aws s3 cp s3://seis665-public/index.php /var/www/html/`
    );

    const web2 = new ec2.Instance(this, 'Web2', {
      vpc,
      instanceType: new ec2.InstanceType(instanceType.valueAsString),
      machineImage: ec2.MachineImage.genericLinux({
        'us-east-1': 'ami-01cc34ab2709337aa',
      }),
      keyName: keyPair.valueAsString,
      securityGroup,
      vpcSubnets: { subnets: [vpc.publicSubnets[1]] },
    });

    web2.addUserData(
      `#!/bin/bash
      yum update -y
      yum install -y git httpd php
      service httpd start
      chkconfig httpd on
      aws s3 cp s3://seis665-public/index.php /var/www/html/`
    );

    // Application LB
    const loadBalancer = new elb.ApplicationLoadBalancer(this, 'EngineeringLB', {
      vpc,
      internetFacing: true,
      securityGroup,
    });

    const targetGroup = new elb.ApplicationTargetGroup(this, 'EngineeringWebservers', {
      vpc,
      port: 80,
      protocol: elb.ApplicationProtocol.HTTP,
      targets: [web1, web2],
    });

    loadBalancer.addListener('ALBListener', {
      port: 80,
      defaultTargetGroups: [targetGroup],
    });

    // Outputs
    new cdk.CfnOutput(this, 'WebUrl', {
      description: 'The URL of ELB',
      value: loadBalancer.loadBalancerDnsName,
    });
  }
}
