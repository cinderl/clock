# Terraform Deployment for Clock Application

This directory contains Terraform configuration to deploy the Clock application Helm chart to a Kubernetes cluster.

## Prerequisites

- Kubernetes cluster running (e.g., via kind as in the deploy-kind.sh script)
- kubectl configured to access the cluster
- Terraform installed
- Helm installed (for dependency management if needed)

## What it does

The Terraform configuration will:
1. Install the Traefik Ingress Controller with the same settings as the deploy-kind.sh script
2. Apply the necessary Traefik CRDs
3. Deploy the Clock application Helm chart

## Usage

1. Ensure your Kubernetes cluster is running and kubectl is configured.

2. Navigate to this directory:
   ```bash
   cd terraform
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Plan the deployment:
   ```bash
   terraform plan
   ```

5. Apply the deployment:
   ```bash
   terraform apply
   ```

6. To destroy the deployment:
   ```bash
   terraform destroy
   ```

## Configuration

The main configuration is in `main.tf`. You can customize values by modifying the `set` blocks or by creating a `values.yaml` file and referencing it.

Note: The chart path is relative to this directory (`../helm/clock-local`). Adjust if needed.