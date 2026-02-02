$LogPath   = "C:\inetpub\logs\LogFiles\W3SVC1"
$OutputCsv = "C:\temp\iis_map_image_requests.csv"

$results = @()

Get-ChildItem $LogPath -Filter *.log | ForEach-Object {

    $fields = @()

    foreach ($line in Get-Content $_.FullName) {

        if ($line -like "#Fields:*") {
            $fields = $line.Substring(8).Split(" ")
            continue
        }

        if ($line -like "#*" -or [string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        # Split ONLY into expected field count
        $values = $line -split " ", $fields.Count

        $entry = @{}
        for ($i = 0; $i -lt $fields.Count; $i++) {
            $entry[$fields[$i]] = $values[$i]
        }

        if ($entry["cs-uri-stem"] -match "MapServer|ImageServer") {
            $results += [pscustomobject]@{
                Date      = $entry["date"]
                Time      = $entry["time"]
                ClientIP  = $entry["c-ip"]
                Method    = $entry["cs-method"]
                Uri       = $entry["cs-uri-stem"]
                Query     = $entry["cs-uri-query"]
                Status    = $entry["sc-status"]
                Bytes     = $entry["sc-bytes"]
                UserAgent = $entry["cs(User-Agent)"]
            }
        }
    }
}

$results | Export-Csv $OutputCsv -NoTypeInformation
Write-Host "Exported $($results.Count) rows to $OutputCsv"
