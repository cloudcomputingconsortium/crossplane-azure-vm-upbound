#!/bin/bash
set -e
echo "Rendering Helm templates for each environment..."

for env in dev stage prod; do
  echo "Validating $env environment..."
  helm template azure-dev-env ./charts/azure-dev-env     --set env=$env     --set location=centralus     --set vmSize=Standard_D2s_v5     --set adminPasswordSecretName=vm-password     --set virtualNetworkName=vnet-$env     --set subnetName=subnet-$env     --set osPublisher=Canonical     --set osOffer=UbuntuServer     --set osSku=20_04-lts-gen2     --set osVersion=latest     --set rbacRole=$env-role     --set tags.CreatedBy=ci@upbound.io     --set tags.Environment=$env     --set tags.Team=platform > /dev/null
  echo "$env passed."
done

echo "All environments validated."
