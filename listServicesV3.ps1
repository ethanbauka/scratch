# Path to ArcGIS Server arcgisinput directory (adjust as needed)
$arcgisInputPath = "D:\arcgisserver\directories\arcgissystem\arcgisinput"
$outCSV = "C:\temp\service_datasources.csv"

$results = @()

# Find all manifest.json files for MapServer or ImageServer services
Get-ChildItem -Path $arcgisInputPath -Recurse -Filter "manifest.json" | ForEach-Object {
    $manifestPath = $_.FullName
    $jsonContent = Get-Content $manifestPath -Raw | ConvertFrom-Json

    # Extract folder/service/type from path
    $serviceFolder = Split-Path $_.Directory.Parent.Parent.Parent.FullName -Leaf
    $serviceName   = Split-Path $_.Directory.Parent.Parent.FullName -Leaf
    $serviceType   = Split-Path $_.Directory.Parent.FullName -Leaf

    # Skip system/utility folders
    if ($serviceFolder -eq "System" -or $serviceFolder -eq "Utilities") {
        return
    }

    if ($null -ne $jsonContent.databases) {
        foreach ($db in $jsonContent.databases) {
            $dbConn = $db.onServerConnectionString
            $datasets = ($db.datasets | ForEach-Object { $_.onServerName }) -join "; "

            $results += [PSCustomObject]@{
                Folder      = $serviceFolder
                Service     = $serviceName
                Type        = $serviceType
                Datasets    = $datasets
                Database    = $dbConn
                Manifest    = $manifestPath
            }
        }
    }
}

# Export results to CSV
$results | Export-Csv -Path $outCSV -NoTypeInformation -Encoding UTF8

Write-Host "Finished writing service datasource inventory to $outCSV"
