# Path to ArcGIS Server config-store (adjust as needed)
$configStorePath = "D:\arcgisserver\config-store\data\items"
$outCSV = "C:\temp\datastores.csv"

# Collect datastore info
$datastores = @()

# Loop through all item JSON files in config-store
Get-ChildItem -Path $configStorePath -Recurse -Filter "*.json" | ForEach-Object {
    $jsonContent = Get-Content $_.FullName -Raw | ConvertFrom-Json

    # Some files may not be datastore definitions, skip those
    if ($null -ne $jsonContent.type) {
        $type = $jsonContent.type

        # Skip system-managed data stores (managed_database, folder, etc.)
        if ($type -eq "MANAGED_DATABASE" -or $type -eq "FOLDER") {
            return
        }

        $id   = $jsonContent.id
        $path = $jsonContent.path
        $info = $jsonContent.info | ConvertTo-Json -Compress

        $datastores += [PSCustomObject]@{
            ID   = $id
            Type = $type
            Path = $path
            Info = $info
        }
    }
}

# Export results
$datastores | Export-Csv -Path $outCSV -NoTypeInformation -Encoding UTF8

Write-Host "Finished writing datastore inventory to $outCSV"
