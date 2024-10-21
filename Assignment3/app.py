#!/usr/bin/env python3
import aws_cdk as cdk
from src.network_stack import NetworkStack
from src.server_stack import ServerStack

app = cdk.App()

# Network Stack
network_stack = NetworkStack(app, "NetworkStack")

# Server Stack depends on Network Stack
server_stack = ServerStack(app, "ServerStack", vpc=network_stack.vpc, public_subnets=network_stack.public_subnets, private_subnets=network_stack.private_subnets)

app.synth()
