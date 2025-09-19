# Paths
$servicesCsv   = "C:\temp\services.csv"
$datastoresCsv = "C:\temp\datastores.csv"

# Import CSVs
$services   = Import-Csv $servicesCsv
$datastores = Import-Csv $datastoresCsv

# Normalization function
function Normalize-ConnString {
    param([string]$value)

    if ([string]::IsNullOrWhiteSpace($value)) { return "" }

    $clean = $value

    # Remove the encrypted password section (case-insensitive)
    $clean = $clean -replace "encrypted_password-UTF8[^;]*;?", "", "IgnoreCase"

    # Remove other noisy prefixes
    $clean = $clean -replace "^DATABASE=", "", "IgnoreCase"
    $clean = $clean -replace "^connectionstring=", "", "IgnoreCase"
    $clean = $clean -replace "^datastoreconnectiontype=", "", "IgnoreCase"
    $clean = $clean -replace "^path=", "", "IgnoreCase"

    # Trim spaces and lowercase for comparison
    return $clean.Trim().ToLower()
}

# Add normalized column to each dataset
$services | ForEach-Object {
    $_ | Add-Member -NotePropertyName "NormalizedConn" -NotePropertyValue (Normalize-ConnString $_.Connection)
}

$datastores | ForEach-Object {
    $_ | Add-Member -NotePropertyName "NormalizedConn" -NotePropertyValue (Normalize-ConnString $_.Info)
}

# Build lists
$serviceConns   = $services.NormalizedConn   | Where-Object { $_ -ne "" } | Sort-Object -Unique
$datastoreConns = $datastores.NormalizedConn | Where-Object { $_ -ne "" } | Sort-Object -Unique

# Find orphans
$orphanServices   = $services   | Where-Object { $_.NormalizedConn -notin $datastoreConns }
$orphanDatastores = $datastores | Where-Object { $_.NormalizedConn -notin $serviceConns }

# Export results
$orphanServices   | Export-Csv "C:\temp\Orphaned_Services.csv" -NoTypeInformation
$orphanDatastores | Export-Csv "C:\temp\Orphaned_DataStores.csv" -NoTypeInformation

Write-Host "Done. Cleaned comparisons exported."
