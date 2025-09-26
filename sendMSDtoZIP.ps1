# PowerShell script to search ArcGIS Server manifest.json files for a string
# Only searches MapServer services
# If a match is found, it zips the .msd file(s) for that service separately

# Root path of ArcGIS Server directories
$rootPath = "D:\arcgisserver\directories\arcgissystem\arcgisinput"

# The string you want to search for
$searchString = "ethanb"

# Where to put packaged results
$outputFolder = "D:\ArcGISServicePackages"

# Create output folder if needed
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# Get all manifest.json files under arcgisinput
$manifestFiles = Get-ChildItem -Path $rootPath -Recurse -Filter "manifest.json" -ErrorAction SilentlyContinue

foreach ($file in $manifestFiles) {
    try {
        $jsonContent = Get-Content -Path $file.FullName -Raw

        if ($jsonContent -match $searchString) {
            # Get service folder (ends with .MapServer)
            $serviceFolder = Split-Path (Split-Path $file.FullName -Parent) -Leaf

            if ($serviceFolder -like "*.MapServer") {
                $servicePath = Split-Path $file.FullName -Parent

                # Find MSD files in this service folder
                $msdFiles = Get-ChildItem -Path $servicePath -Recurse -Filter *.msd -ErrorAction SilentlyContinue

                if ($msdFiles) {
                    # Build output zip name based on service folder
                    $zipPath = Join-Path $outputFolder "$serviceFolder.zip"

                    if (Test-Path $zipPath) {
                        Remove-Item $zipPath -Force
                    }

                    Compress-Archive -Path $msdFiles.FullName -DestinationPath $zipPath

                    Write-Host "Packaged MSD for $serviceFolder into $zipPath"
                } else {
                    Write-Warning "No .msd file found for $serviceFolder"
                }
            }
        }
    }
    catch {
        Write-Warning "Failed to read $($file.FullName): $_"
    }
}
