# Path to IIS log directory (update site ID if needed)
$LogPath = "C:\inetpub\logs\LogFiles\W3SVC1"
$OutputCsv = "C:\temp\iis_map_image_requests.csv"

$results = @()

Get-ChildItem $LogPath -Filter *.log | ForEach-Object {

    $fields = @()
    
    Get-Content $_.FullName | ForEach-Object {

        # Capture field definitions
        if ($_ -like "#Fields:*") {
            $fields = $_.Substring(8).Split(" ")
            return
        }

        # Skip comments
        if ($_ -like "#*") { return }

        # Parse log line
        $values = $_.Split(" ")
        if ($fields.Count -ne $values.Count) { return }

        $entry = @{}
        for ($i = 0; $i -lt $fields.Count; $i++) {
            $entry[$fields[$i]] = $values[$i]
        }

        # Filter ArcGIS Map/Image services
        if ($entry["cs-uri-stem"] -match "MapServer|ImageServer") {
            $results += [pscustomobject]@{
                Date        = $entry["date"]
                Time        = $entry["time"]
                ClientIP    = $entry["c-ip"]
                Method      = $entry["cs-method"]
                UriStem     = $entry["cs-uri-stem"]
                UriQuery    = $entry["cs-uri-query"]
                Status      = $entry["sc-status"]
                BytesSent   = $entry["sc-bytes"]
                UserAgent   = $entry["cs(User-Agent)"]
            }
        }
    }
}

# Export results
$results | Export-Csv $OutputCsv -NoTypeInformation

Write-Host "Export complete: $OutputCsv"
