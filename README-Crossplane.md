# Crossplane Azure DevEnvironment Deployment on AKS

This repository provides a complete GitOps + Helm-based setup to provision Azure Virtual Machines using Upbound Crossplane on Azure Kubernetes Service (AKS).

---

## How to Install Upbound Crossplane on AKS

### Prerequisites
- A running AKS cluster (`kubectl` configured)
- Helm installed (`helm version`)
- Cluster admin permissions

### 1. Install Crossplane via Helm

```bash
helm repo add upbound-stable https://charts.upbound.io/stable
helm repo update

helm install crossplane upbound-stable/crossplane --namespace crossplane-system --create-namespace
```

### 2. Install the Azure Provider

```bash
kubectl crossplane install provider crossplane-contrib/provider-azure
```

Or:

```bash
kubectl apply -f https://raw.githubusercontent.com/crossplane-contrib/provider-azure/main/examples/install.yaml
```

### 3. Create Azure ProviderConfig

#### a. Create an Azure service principal:

```bash
az ad sp create-for-rbac \
  --name crossplane-sp \
  --role Contributor \
  --scopes /subscriptions/<your-subscription-id> \
  --sdk-auth
```

#### b. Store the credentials in a Kubernetes secret:

```bash
kubectl create secret generic azure-creds -n crossplane-system \
  --from-file=creds=./azure-creds.json
```

#### c. Create the ProviderConfig:

```yaml
apiVersion: azure.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: azure-provider
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: azure-creds
      key: creds
```

Apply it:

```bash
kubectl apply -f providerconfig.yaml
```

### 4. Verify Installation

```bash
kubectl get all -n crossplane-system
kubectl get providers
```

---

## Additional Steps

- Use `kubectl apply -f claim.yaml` to provision VMs
- GitOps support is available using FluxCD Kustomizations for `dev`, `stage`, and `prod`
- Secrets are encrypted using Mozilla SOPS under `/secrets`

---

## Folder Structure

- `charts/azure-dev-env/` – Helm chart to render reusable infrastructure
- `environments/` – GitOps Kustomizations for dev/stage/prod
- `secrets/` – SOPS-encrypted secrets for password and RBAC
- `ci/validate-helm.sh` – CI/CD validation script for Helm rendering

Strategy: Use Kubernetes Provider in Crossplane to Run an Azure Bicep Job
Crossplane can use the provider-kubernetes to create a Kubernetes Job that:

Runs an az deployment command

Executes a .bicep file (mounted or pulled from a ConfigMap or container image)

Step-by-Step Overview
1. Deploy the infrastructure (VM, VNet, NIC, etc.) using Crossplane XRD/Claim (as you’re already doing).
2. Define a Kubernetes Job that runs Azure CLI commands to deploy your backup + monitoring .bicep file:

apiVersion: batch/v1
kind: Job
metadata:
  name: vm-monitoring-job
  namespace: crossplane-system
spec:
  template:
    spec:
      containers:
        - name: deploy-monitoring
          image: mcr.microsoft.com/azure-cli
          command:
            - /bin/bash
            - -c
            - |
              az login --identity
              az deployment group create \
                --resource-group my-rg \
                --template-file /scripts/vm-monitoring.bicep \
                --parameters vmName=myVM logAnalyticsWorkspace=log-ws
          volumeMounts:
            - name: bicep-scripts
              mountPath: /scripts
      restartPolicy: OnFailure
      volumes:
        - name: bicep-scripts
          configMap:
            name: vm-monitoring-bicep

3. Package your .bicep into a ConfigMap:

apiVersion: v1
kind: ConfigMap
metadata:
  name: vm-monitoring-bicep
  namespace: crossplane-system
data:
  vm-monitoring.bicep: |
    <INSERT-YOUR-BICEP-CONTENT-HERE>

4. Trigger the above Job using Crossplane via provider-kubernetes
Crossplane can apply that Job with:

apiVersion: kubernetes.crossplane.io/v1alpha1
kind: Object
metadata:
  name: monitoring-job-trigger
  namespace: crossplane-system
spec:
  forProvider:
    manifest:
      apiVersion: batch/v1
      kind: Job
      metadata:
        name: vm-monitoring-job
        namespace: crossplane-system
      spec: <...job spec as above...>
  providerConfigRef:
    name: local-k8s

Summary
You can’t directly run a Bicep file via kubectl apply, but you can trigger it indirectly via:

A Kubernetes Job that runs az deployment

A provider-kubernetes resource in Crossplane to trigger the Job

A ConfigMap to hold your Bicep script

Included in /monitoring/:
configmap.yaml
Holds your vm-monitoring.bicep logic as a ConfigMap in Kubernetes

job.yaml
A Kubernetes Job that mounts the Bicep and calls az deployment group create

crossplane-object.yaml
A Crossplane Object (via provider-kubernetes) that declaratively triggers the job from within Crossplane GitOps flows

How to Use:
Apply the ConfigMap and Crossplane Object:

kubectl apply -f monitoring/configmap.yaml
kubectl apply -f monitoring/crossplane-object.yaml

Ensure:

The VM and Log Analytics Workspace exist

The pod can authenticate via Managed Identity (az login --identity)

The provider-kubernetes is configured in Crossplane as local-k8s

monitoring/
provider-kubernetes-install.yaml – Automatically installs the provider-kubernetes package via Crossplane

configmap.yaml – Embeds the Bicep for Log Analytics and diagnostics

job.yaml – Runs the Azure CLI inside a pod to deploy the Bicep

crossplane-object.yaml – Triggers the job via Crossplane's Kubernetes provider

charts/azure-dev-env/templates/
monitoring-job.yaml – Helm-templated version of the job trigger (GitOps-ready)

flux/
kustomization-monitoring.yaml – FluxCD integration for the monitoring deployment

How to Use:
Install provider-kubernetes:

kubectl apply -f monitoring/provider-kubernetes-install.yaml
Deploy the FluxCD Kustomization:

kubectl apply -f flux/kustomization-monitoring.yaml
This ensures your Crossplane platform can declaratively launch Bicep-based extensions (like backup and monitoring) inside GitOps flows.
