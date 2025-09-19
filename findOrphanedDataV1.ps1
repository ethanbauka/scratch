# Paths
$servicesCsv   = "C:\temp\services.csv"
$datastoresCsv = "C:\temp\datastores.csv"

# Import CSVs
$services   = Import-Csv $servicesCsv
$datastores = Import-Csv $datastoresCsv

# Normalize function
function Normalize-ConnString {
    param([string]$value)

    if ([string]::IsNullOrWhiteSpace($value)) { return "" }

    # Remove common prefixes and make lowercase for comparison
    $clean = $value -replace '^encrypted_password-UTF8', '' `
                     -replace '^DATABASE=', '' `
                     -replace '^connectionstring=', '' `
                     -replace '^datastoreconnectiontype=', '' `
                     -replace '^path=', ''

    return $clean.Trim().ToLower()
}

# Normalize both sets
$services | ForEach-Object {
    $_ | Add-Member -NotePropertyName "NormalizedConn" -NotePropertyValue (Normalize-ConnString $_.Connection)
}

$datastores | ForEach-Object {
    $_ | Add-Member -NotePropertyName "NormalizedConn" -NotePropertyValue (Normalize-ConnString $_.Info)
}

# Find orphans
$serviceConns   = $services.NormalizedConn | Where-Object { $_ -ne "" } | Sort-Object -Unique
$datastoreConns = $datastores.NormalizedConn | Where-Object { $_ -ne "" } | Sort-Object -Unique

$orphanServices   = $services   | Where-Object { $_.NormalizedConn -notin $datastoreConns }
$orphanDatastores = $datastores | Where-Object { $_.NormalizedConn -notin $serviceConns }

# Export results
$orphanServices   | Export-Csv "C:\temp\Orphaned_Services.csv" -NoTypeInformation
$orphanDatastores | Export-Csv "C:\temp\Orphaned_DataStores.csv" -NoTypeInformation

Write-Host "Done. Orphaned services and datastores exported."
