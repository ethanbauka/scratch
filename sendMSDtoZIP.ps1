# Root path of ArcGIS Server directories
$rootPath = "D:\arcgisserver\directories\arcgissystem\arcgisinput"

# The string you want to search for in manifest.json
$searchString = "ethanb"

# Where to put packaged results
$outputFolder = "D:\ArcGISServicePackages"

if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# Get all manifest.json files
$manifestFiles = Get-ChildItem -Path $rootPath -Recurse -Filter "manifest.json" -ErrorAction SilentlyContinue

foreach ($file in $manifestFiles) {
    try {
        $jsonContent = Get-Content -Path $file.FullName -Raw

        if ($jsonContent -match $searchString) {
            # Service folder (e.g. Parcels.MapServer)
            $serviceFolder = Split-Path (Split-Path $file.FullName -Parent) -Leaf

            if ($serviceFolder -like "*.MapServer") {
                Write-Host ">>> Match found in service: $serviceFolder"

                # Full path to the service folder
                $serviceDir = Split-Path (Split-Path $file.FullName -Parent) -Parent

                # Output zip path
                $zipPath = Join-Path $outputFolder "$serviceFolder.zip"

                if (Test-Path $zipPath) {
                    Remove-Item $zipPath -Force
                }

                # Zip the entire service folder
                Compress-Archive -Path $serviceDir -DestinationPath $zipPath

                Write-Host "    Packaged full service folder into $zipPath"
            }
        }
    }
    catch {
        Write-Warning "Failed to read $($file.FullName): $_"
    }
}
