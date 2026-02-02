$LogPath   = "C:\inetpub\logs\LogFiles\W3SVC1"
$OutputCsv = "C:\temp\iis_all_requests.csv"

$rows = @()

Get-ChildItem $LogPath -Filter *.log | ForEach-Object {

    $fields = @()

    foreach ($line in Get-Content $_.FullName) {

        if ($line.StartsWith("#Fields:")) {
            $fields = $line.Replace("#Fields: ","").Split(" ")
            continue
        }

        if ($line.StartsWith("#") -or !$fields) { continue }

        $values = $line -split " ", $fields.Count

        $obj = [ordered]@{}
        for ($i=0; $i -lt $fields.Count; $i++) {
            $obj[$fields[$i]] = $values[$i]
        }

        $rows += [pscustomobject]$obj
    }
}

$rows | Export-Csv $OutputCsv -NoTypeInformation
Write-Host "Rows exported:" $rows.Count
