# PowerShell script to search ArcGIS Server manifest.json files
# Looks for a given string in all MapServer manifest.json files

# Root path of ArcGIS Server directories
$rootPath = "D:\arcgisserver\directories\arcgissystem\arcgisinput"

# The string you want to search for
$searchString = "folder_or_username_here"

# Collect results
$results = @()

# Get all manifest.json files in MapServer folders
$manifestFiles = Get-ChildItem -Path $rootPath -Recurse -Filter "manifest.json" -ErrorAction SilentlyContinue

foreach ($file in $manifestFiles) {
    try {
        $jsonContent = Get-Content -Path $file.FullName -Raw

        if ($jsonContent -match $searchString) {
            # Extract service name from path (folder before ".MapServer")
            $servicePath = $file.FullName
            $serviceName = ($servicePath -split "\\") -match "\.MapServer" | Out-Null
            $serviceName = ($servicePath -split "\\") | Where-Object { $_ -like "*.MapServer" }

            $results += [PSCustomObject]@{
                ServiceName = $serviceName
                FilePath    = $file.FullName
            }
        }
    }
    catch {
        Write-Warning "Failed to read $($file.FullName): $_"
    }
}

# Output results
if ($results.Count -gt 0) {
    $results | Format-Table -AutoSize
    # Optional: export to CSV
    $results | Export-Csv -Path ".\ServicesWith_$searchString.csv" -NoTypeInformation
    Write-Host "Results saved to ServicesWith_$searchString.csv"
} else {
    Write-Host "No services found containing '$searchString'."
}
