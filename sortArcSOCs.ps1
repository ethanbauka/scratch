# Get-ArcSOCInfo.ps1
# Lists ArcSOC.exe processes with PID, Service Name, Service Type, and RAM usage

function Parse-ArcSOCCommandLine {
    param(
        [string]$cmd
    )

    $serviceType = ""
    $serviceName = ""

    # Look for -Dservice=<folder>.<service>.<type>
    if ($cmd -match "-Dservice=([A-Za-z0-9_.]+)") {
        $full = $matches[1]
        $parts = $full -split "\."

        if ($parts.Length -ge 3) {
            $serviceType = $parts[-1]                       # MapServer or GPServer
            $serviceName = ($parts[0..($parts.Length-2)] -join ".")
        }
        else {
            $serviceName = $full
        }
    }

    return [PSCustomObject]@{
        ServiceType = $serviceType
        ServiceName = $serviceName
    }
}

# Get ArcSOC processes with memory info
$procs = Get-CimInstance Win32_Process -Filter "Name='ArcSOC.exe'"

$results = foreach ($p in $procs) {

    $parsed = Parse-ArcSOCCommandLine -cmd $p.CommandLine

    # WorkingSetSize = RAM usage in bytes -> convert to MB
    $ramMB = [Math]::Round(($p.WorkingSetSize / 1MB), 1)

    [PSCustomObject]@{
        PID         = $p.ProcessId
        RAM_MB      = $ramMB
        ServiceType = $parsed.ServiceType
        ServiceName = $parsed.ServiceName
    }
}

# Sort by ServiceName alphabetically
$results | Sort-Object ServiceName | Format-Table -AutoSize
