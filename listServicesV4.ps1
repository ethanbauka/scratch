# Path to ArcGIS Server config-store
$configStorePath = "D:\arcgisserver\config-store\services"
$outCSV = "C:\temp\manifest_datasources.csv"

$results = @()

# Find all manifest.json files
Get-ChildItem -Path $configStorePath -Recurse -Filter "manifest.json" | ForEach-Object {
    $manifest = Get-Content $_.FullName -Raw | ConvertFrom-Json

    # Derive service info from path
    $serviceTypeDir = Split-Path $_.Directory.Parent.Parent.FullName -Leaf   # e.g. MyService.MapServer
    $serviceFolder  = Split-Path $_.Directory.Parent.Parent.Parent.FullName -Leaf # folder name or 'services'
    if ($serviceFolder -eq "services") { $serviceFolder = "Root" }
    $serviceName = $serviceTypeDir -replace "\.(MapServer|ImageServer)$",""
    $serviceType = ($serviceTypeDir -split "\.")[-1]

    # Database connections
    if ($null -ne $manifest.databases) {
        foreach ($db in $manifest.databases) {
            foreach ($ds in $db.datasets) {
                $results += [PSCustomObject]@{
                    Folder        = $serviceFolder
                    Service       = $serviceName
                    Type          = $serviceType
                    Database      = $db.datasourceName
                    Connection    = $db.onServerConnectionString
                    DatasetName   = $ds.datasetName
                    OnServerName  = $ds.onServerName
                    OnServerType  = $ds.onServerType
                }
            }
        }
    }

    # File GDB / shapefiles or other datasets
    if ($null -ne $manifest.datasets) {
        foreach ($ds in $manifest.datasets) {
            $results += [PSCustomObject]@{
                Folder        = $serviceFolder
                Service       = $serviceName
                Type          = $serviceType
                Database      = "N/A"
                Connection    = "N/A"
                DatasetName   = $ds.datasetName
                OnServerName  = $ds.onServerName
                OnServerType  = $ds.onServerType
            }
        }
    }
}

# Export results to CSV
$results | Export-Csv -Path $outCSV -NoTypeInformation -Encoding UTF8

Write-Host "Finished writing manifest datasource inventory to $outCSV"
