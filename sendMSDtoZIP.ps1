# Root path of ArcGIS Server directories
$rootPath = "D:\arcgisserver\directories\arcgissystem\arcgisinput"

# The string you want to search for in manifest.json
$searchString = "ethanb"

# Destination folder for copied services
$destRoot = "E:\ArcGISServiceCopies"

if (-not (Test-Path $destRoot)) {
    New-Item -ItemType Directory -Path $destRoot | Out-Null
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

                # Destination path
                $destPath = Join-Path $destRoot $serviceFolder

                # Remove old copy if it exists
                if (Test-Path $destPath) {
                    Remove-Item -Path $destPath -Recurse -Force
                }

                # Copy entire service folder
                Copy-Item -Path $serviceDir -Destination $destPath -Recurse -Force

                Write-Host "    Copied $serviceFolder to $destPath"
            }
        }
    }
    catch {
        Write-Warning "Failed to process $($file.FullName): $_"
    }
}
