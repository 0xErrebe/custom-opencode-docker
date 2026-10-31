<#>
.SYNOPSIS
    Run OpenCode in an ephemeral Podman container with project and config mounted.

.DESCRIPTION
    Creates a throwaway container for the current project directory, mounts
    ~/.config/opencode and ~/.local/share/opencode for config + auth + sessions,
    and attaches the TUI inside the container. Container is removed on exit.

.USAGE
    cd C:\path\to\myapp
    opencode-sandbox
    # or with args passed through to opencode:
    opencode-sandbox --model anthropic/claude-3.5-sonnet
#>

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$OpencodeArgs
)

# ---- Config ----
# Replace <OWNER> with your GitHub username/org once the repo exists.
$ImageOwner = "<OWNER>"
$Image = "ghcr.io/$ImageOwner/opencode-sandbox:latest"
$Workdir = "/workdir"
$ConfigMount = "$env:USERPROFILE\.config\opencode"
$DataMount   = "$env:USERPROFILE\.local\share\opencode"
$ContainerPrefix = "oc-sandbox-"

# ---- Helpers ----
function Get-ProjectHash {
    $path = (Get-Location).Path
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($path.ToLower())
    $hash = [System.Security.Cryptography.MD5]::Create().ComputeHash($bytes)
    $hashStr = -join ($hash | ForEach-Object { $_.ToString("x2") })
    return $hashStr.Substring(0, [Math]::Min(12, $hashStr.Length))
}

function Test-PodmanRunning {
    podman info --format '{{.Host.Arch}}' *> $null
    return ($LASTEXITCODE -eq 0)
}

function Cleanup-StaleContainers {
    $stale = @("opencode-spike", "nettest", "chatgpt2api")
    foreach ($name in $stale) {
        if (podman ps -a --format "{{.Names}}" | Select-String -Quiet "^$name$") {
            Write-Host "Removing stale container: $name" -ForegroundColor Yellow
            podman rm -f $name 2>$null
        }
    }
}

# ---- Main ----
if (-not (Test-PodmanRunning)) {
    Write-Error "Podman is not running. Start it with: podman machine start"
    exit 1
}

Cleanup-StaleContainers

$projectHash = Get-ProjectHash
$containerName = "$ContainerPrefix$projectHash"
$projectPath = (Get-Location).Path

# Verify mount sources exist
if (-not (Test-Path $ConfigMount)) {
    Write-Warning "Config dir not found: $ConfigMount (continuing anyway)"
}
if (-not (Test-Path $DataMount)) {
    Write-Warning "Data dir not found: $DataMount (continuing anyway)"
}

Write-Host "Starting OpenCode sandbox for: $projectPath" -ForegroundColor Cyan
Write-Host "Container: $containerName" -ForegroundColor Gray

# Download the latest published image; fail hard if unavailable.
Write-Host "Pulling image: $Image" -ForegroundColor Gray
podman pull $Image
if ($LASTEXITCODE -ne 0) {
    Write-Error "Could not pull $Image. Check that the repo exists, that <OWNER> is replaced, and that the package is public on ghcr.io."
    exit 1
}

$podmanArgs = @(
    "run",
    "--rm",                          # ephemeral - removed on exit
    "-it",                           # interactive TTY for TUI
    "--name", $containerName,
    "-v", "${PWD}:${Workdir}",
    "-v", "${ConfigMount}/opencode-sandbox.jsonc:/etc/opencode/opencode.json",
    "-v", "${ConfigMount}:/root/.config/opencode",
    "-v", "${DataMount}:/root/.local/share/opencode/",
    "-w", $Workdir,
    $Image
) + $OpencodeArgs

# Run and attach (run -it blocks until exit, then --rm cleans up)
try {
    & podman @podmanArgs
} catch {
    Write-Error "Failed to start container: $_"
    exit 1
}