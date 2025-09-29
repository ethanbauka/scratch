# Root path of ArcGIS Server directories
$rootPath = "D:\arcgisserver\directories\arcgissystem\arcgisinput"

# The string you want to search for
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
            # Get service folder (e.g. Parcels.MapServer)
            $serviceFolder = Split-Path (Split-Path $file.FullName -Parent) -Leaf

            if ($serviceFolder -like "*.MapServer") {
                Write-Host ">>> Match found in service: $serviceFolder"

                # Look inside extracted/pXX for mapx files
                $serviceDir = Split-Path (Split-Path $file.FullName -Parent) -Parent
                $extractedDir = Join-Path $serviceDir "extracted"

                $mapxFiles = Get-ChildItem -Path $extractedDir -Recurse -Filter *.mapx -ErrorAction SilentlyContinue

                if ($mapxFiles) {
                    $zipPath = Join-Path $outputFolder "$serviceFolder.zip"
                    if (Test-Path $zipPath) {
                        Remove-Item $zipPath -Force
                    }
                    Compress-Archive -Path $mapxFiles.FullName -DestinationPath $zipPath
                    Write-Host "    Packaged $($mapxFiles.Count) MAPX file(s) into $zipPath"
                }
                else {
                    Write-Warning "    No .mapx file found for $serviceFolder under $extractedDir"
                }
            }
        }
    }
    catch {
        Write-Warning "Failed to read $($file.FullName): $_"
    }
}
