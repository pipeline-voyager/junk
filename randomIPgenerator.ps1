# random ip + subnet generator

$Count = Read-Host "How many IPs do you want to generate?"

if (-not [int]::TryParse($Count, [ref]$null) -or [int]$Count -lt 1) {
    Write-Host "Enter a valid number." -ForegroundColor Red
    exit
}

$Count = [int]$Count

$Delay = Read-Host "Delay between IPs in milliseconds (0 = no delay)"

if (-not [int]::TryParse($Delay, [ref]$null) -or [int]$Delay -lt 0) {
    Write-Host "Enter a valid delay." -ForegroundColor Red
    exit
}

$Delay = [int]$Delay

$OutputFile = Read-Host "Output filename (press Enter for random_ips.txt)"

if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    $OutputFile = "random_ips.txt"
}

$Random = [System.Random]::new()

# get a random ip
function Get-RandomIP {
    do {
        $a = $Random.Next(1, 224)
        $b = $Random.Next(0, 256)
        $c = $Random.Next(0, 256)
        $d = $Random.Next(1, 255)

        $IP = "$a.$b.$c.$d"

        # skip private/reserved ip ranges
        $Invalid =
            ($a -eq 10) -or
            ($a -eq 127) -or
            ($a -eq 169 -and $b -eq 254) -or
            ($a -eq 172 -and $b -ge 16 -and $b -le 31) -or
            ($a -eq 192 -and $b -eq 168) -or
            ($a -eq 0) -or
            ($a -ge 224)

    } while ($Invalid)

    return $IP
}

$Results = [System.Collections.Generic.List[string]]::new()
$Used = [System.Collections.Generic.HashSet[string]]::new()

Write-Host "`nGenerating $Count IPs..." -ForegroundColor Cyan

while ($Results.Count -lt $Count) {

    $IP = Get-RandomIP

    # random cidr
    $CIDR = $Random.Next(8, 33)

    $Entry = "$IP/$CIDR"

    # dont add duplicates
    if ($Used.Add($Entry)) {
        $Results.Add($Entry)

        Write-Host $Entry

        if ($Results.Count % 1000 -eq 0) {
            Write-Host "$($Results.Count) / $Count generated..." -ForegroundColor DarkGray
        }

        # delay between each ip
        if ($Delay -gt 0) {
            Start-Sleep -Milliseconds $Delay
        }
    }
}

$Results | Set-Content -Path $OutputFile -Encoding UTF8

Write-Host "`nFinished!" -ForegroundColor Green
Write-Host "Generated: $($Results.Count)"
Write-Host "Saved to: $OutputFile"
