# 
# This scripts adds necessary project and applications into argo cd
#
# usage:
#   src/infrastructure/ArgoCD/bootstrap.ps1

# updating github secrets
# kubectl -n 2025-backstage get secret backstage-secrets -o json | jq ".data[`"AUTH_GITHUB_CLIENT_ID`"]=`"$env:AUTH_GITHUB_CLIENT_ID`" | .data[`"AUTH_GITHUB_CLIENT_SECRET`"]=`"$env:AUTH_GITHUB_CLIENT_SECRET`" " | kubectl apply -f -

[CmdletBinding()]
param()

$kubeNamespace = "2025-backstage"
$scriptDirectory = $PSScriptRoot


function Invoke-Main() {
    # Check-KubeCtlCommand
    # Create-KubeCtlNs
    # Apply-ArgoProject
    # Apply-ArgoApplication

    Create-Secrets-Postgres
    Create-Secrets-Backstage
}

function Create-KubeCtlNs() {
    kubectl create namespace $kubeNamespace --dry-run=client -o yaml | kubectl apply -f -
    if ($LASTEXITCODE -ne 0) {
        Handle-Error "Failed to create namespace '$kubeNamespace'."
    }
}

function Apply-ArgoProject() {
    $yamlFile = "$scriptDirectory/argoproject.yaml"
    Write-Host "Applying ArgoCD Project configuration from '$yamlFile'..."
    kubectl apply -f $yamlFile
    if ($LASTEXITCODE -ne 0) {
        Handle-Error "Failed to apply $yamlFile."
    } else {
        Write-Host "ArgoCD Project configuration applied successfully."
    }
}

function Apply-ArgoApplication() {
    $yamlFile = "$scriptDirectory/argoapplication.yaml"
    Write-Host "Applying ArgoCD Application configuration from '$yamlFile'..."
    kubectl apply -f $yamlFile
    if ($LASTEXITCODE -ne 0) {
        Handle-Error "Failed to apply $yamlFile."
    } else {
        Write-Host "ArgoCD Application configuration applied successfully."
    }
}

function Create-Secrets-Postgres() {
    $password = Generate-Secret 20

    kubectl create secret generic postgres-db-secrets `
        --save-config `
        --dry-run=client `
        --from-literal=username=postgres `
        --from-literal=password="$password" `
        -n $kubeNamespace `
        -o yaml `
        | kubectl apply -f -
    
    if ($LASTEXITCODE -ne 0) {
        Handle-Error "Failed to create secrets."
    } else {
        Write-Host "Secrets for Postgres successfully created."
    }
}

function Create-Secrets-Backstage() {

  kubectl create secret generic backstage-secrets `
      --save-config `
      --dry-run=client `
      --from-literal=GITHUB_TOKEN=todo `
      --from-literal=AUTH_GITHUB_CLIENT_ID=todo `
      --from-literal=AUTH_GITHUB_CLIENT_SECRET=todo `
      -n $kubeNamespace `
      -o yaml `
      | kubectl apply -f -
  
  if ($LASTEXITCODE -ne 0) {
      Handle-Error "Failed to create secrets."
  } else {
      Write-Host "Secrets for Backstage successfully created."
  }
}

function Generate-Secret() {
    param(
        [int]$Length = 20
    )
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+'
    -join (1..$Length | ForEach-Object { $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)] })
}

function Check-KubeCtlCommand() {
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Handle-Error "kubectl is not installed or not in the system's PATH."
    }
}

function Handle-Error {
    param(
        [string]$Message
    )
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

Invoke-Main
