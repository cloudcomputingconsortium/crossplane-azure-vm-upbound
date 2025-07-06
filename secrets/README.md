# SOPS Encrypted Secrets

This folder contains sensitive Kubernetes secrets that should be encrypted using Mozilla SOPS before being committed to Git.

## How to Encrypt

1. Generate an Age key if you don't have one:

   ```bash
   age-keygen -o age.key
   export SOPS_AGE_KEY_FILE=age.key
   ```

2. Encrypt the secrets:

   ```bash
   sops -e -i sensitive-secrets.yaml
   ```

3. Apply with FluxCD (must configure `sops-age-key` in `flux-system` namespace):

   ```bash
   kubectl apply -f sensitive-secrets.yaml
   ```

## Creating the Decryption Secret for Flux

```bash
kubectl create secret generic sops-age-key \
  --namespace=flux-system \
  --from-file=age.agekey=age.key \
  --type=Opaque
```

Ensure this secret is referenced in your `Kustomization`:

```yaml
decryption:
  provider: sops
  secretRef:
    name: sops-age-key
```
