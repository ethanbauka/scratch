# Path to ArcGIS Server config-store (adjust as needed)
$configStorePath = "D:\arcgisserver\config-store\services"
$outCSV = "C:\temp\service_datasources.csv"

$results = @()

# Loop through all service.json files in the config-store
Get-ChildItem -Path $configStorePath -Recurse -Filter "service.json" | ForEach-Object {
    $jsonContent = Get-Content $_.FullName -Raw | ConvertFrom-Json

    # Identify folder/service/type from the path
    $serviceFolder = Split-Path $_.Directory.Parent.FullName -Leaf
    $serviceName   = Split-Path $_.Directory.FullName -Leaf

    # Skip system/utility folders
    if ($serviceFolder -eq "System" -or $serviceFolder -eq "Utilities") {
        return
    }

    # Handle "databases" block
    if ($null -ne $jsonContent.databases) {
        foreach ($db in $jsonContent.databases) {
            $dbConn = $db.onServerConnectionString
            $datasets = ($db.datasets | ForEach-Object { $_.onServerName }) -join "; "

            $results += [PSCustomObject]@{
                Folder   = $serviceFolder
                Service  = $serviceName
                Datasets = $datasets
                Database = $dbConn
            }
        }
    }
    # Handle "datasets" block
    elseif ($null -ne $jsonContent.datasets) {
        $datasets = ($jsonContent.datasets | ForEach-Object { $_.onServerName }) -join "; "

        $results += [PSCustomObject]@{
            Folder   = $serviceFolder
            Service  = $serviceName
            Datasets = $datasets
            Database = "N/A"
        }
    }
}

# Export results to CSV
$results | Export-Csv -Path $outCSV -NoTypeInformation -Encoding UTF8

Write-Host "Finished writing service datasource inventory to $outCSV"
