# Project 3 — Highly Available Web Application

## Overview

This project demonstrates how to build a highly available AWS network architecture using Terraform.

The infrastructure is designed across multiple Availability Zones, with separate public and private subnets. Public resources can access the internet through an Internet Gateway, while private resources use a NAT Gateway for outbound internet access without being directly exposed to the public internet.

## Architecture

```text
                    Internet
                       |
                       v
                Internet Gateway
                       |
              +--------+--------+
              |                 |
              v                 v
        Public Subnet A   Public Subnet B
        ap-southeast-1a   ap-southeast-1b
              |                 |
              +--------+--------+
                       |
                  NAT Gateway
                       |
              +--------+--------+
              |                 |
              v                 v
       Private Subnet A   Private Subnet B
       ap-southeast-1a    ap-southeast-1b