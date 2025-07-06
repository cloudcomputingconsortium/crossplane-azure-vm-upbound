# 🔐 Connect to AKS from a Linux VM Jumpbox

This guide explains how to securely access an Azure Kubernetes Service (AKS) cluster from a Linux-based jumpbox VM.

---

## ✅ Step-by-Step Instructions

### 1. SSH into the Jumpbox

```bash
ssh azureuser@<jumpbox-public-ip>
```

---

### 2. Install Required CLI Tools

#### a. Azure CLI
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### b. kubectl
```bash
az aks install-cli
```

---

### 3. Authenticate with Azure

#### Option A: Using Managed Identity (Recommended for Jumpboxes in Azure)

```bash
az login --identity
```

#### Option B: Using a Service Principal

```bash
az login --service-principal \
  --username <appId> \
  --password <client-secret> \
  --tenant <tenant-id>
```

---

### 4. Fetch AKS Credentials

```bash
az aks get-credentials \
  --name <aks-cluster-name> \
  --resource-group <aks-resource-group> \
  --overwrite-existing
```

This will update `~/.kube/config` with your AKS context.

---

### 5. Verify Access

```bash
kubectl get nodes
```

If successful, you’ll see your AKS worker nodes.

---

## 🔐 Security Recommendations

- Ensure NSG or firewall rules allow port `443` from the jumpbox to the AKS API server.
- Use Azure AD-integrated RBAC or Kubernetes RBAC for least privilege access.
- Rotate service principal secrets or tokens periodically if using non-managed identities.

---

## 📁 Location

This README belongs in any secure ops repository or Terraform automation that provisions jumpboxes for AKS access.
