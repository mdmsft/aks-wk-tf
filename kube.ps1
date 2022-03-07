[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $Name
)

$ErrorActionPreference = "Stop"

$config = (kubectl config get-contexts $Name --no-headers).split() | Where-Object { $_.Length -gt 0 } | Select-Object $_
$context = $config[0]
$cluster = $config[1]
$user = $config[2]

kubectl config delete-context $context
kubectl config delete-cluster $cluster
kubectl config delete-user $user