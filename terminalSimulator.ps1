# terminal simulator

Clear-Host

$green = "Green"
$darkGreen = "DarkGreen"
$red = "Red"
$cyan = "Cyan"
$yellow = "Yellow"

function Write-Type {
    param (
        [string]$Text,
        [int]$Speed = 15
    )

    foreach ($Char in $Text.ToCharArray()) {
        Write-Host -NoNewline $Char -ForegroundColor $green
        Start-Sleep -Milliseconds $Speed
    }

    Write-Host
}

function Get-RandomIP {
    $a = Get-Random -Minimum 11 -Maximum 223
    $b = Get-Random -Minimum 0 -Maximum 256
    $c = Get-Random -Minimum 0 -Maximum 256
    $d = Get-Random -Minimum 1 -Maximum 255

    return "$a.$b.$c.$d"
}

function Show-Progress {
    param (
        [string]$Text
    )

    Write-Host "`n$Text" -ForegroundColor $cyan

    for ($i = 0; $i -le 100; $i += 5) {
        Write-Progress `
            -Activity $Text `
            -Status "$i% complete" `
            -PercentComplete $i

        Start-Sleep -Milliseconds (Get-Random -Minimum 30 -Maximum 120)
    }

    Write-Progress -Activity $Text -Completed
}

# startup

Write-Host ""
Write-Host "==========================================" -ForegroundColor $darkGreen
Write-Host "        TERMINAL SIMULATOR v1.0           " -ForegroundColor $green
Write-Host "==========================================" -ForegroundColor $darkGreen
Write-Host ""

Start-Sleep -Seconds 1

Write-Type "[+] starting terminal..."
Start-Sleep -Milliseconds 500

Write-Type "[+] loading modules..."
Start-Sleep -Milliseconds 500

Write-Type "[+] connecting to simulation..."
Start-Sleep -Milliseconds 500

Write-Host ""
Write-Type "connection established." 30

# menu

while ($true) {

    Write-Host ""
    Write-Host "============== MENU ==============" -ForegroundColor $cyan
    Write-Host "1. Scan random IPs"
    Write-Host "2. Generate random IP"
    Write-Host "3. Run fake system scan"
    Write-Host "4. Show system information"
    Write-Host "5. Exit"
    Write-Host "==================================" -ForegroundColor $cyan
    Write-Host ""

    $Choice = Read-Host "Choose an option"

    switch ($Choice) {

        "1" {
            Clear-Host

            $Amount = Read-Host "How many IPs do you want to scan?"

            if (-not [int]::TryParse($Amount, [ref]$null) -or [int]$Amount -lt 1) {
                Write-Host "Invalid number." -ForegroundColor $red
                continue
            }

            $Amount = [int]$Amount

            Write-Host ""
            Write-Type "starting simulated scan..."
            Write-Host ""

            for ($i = 1; $i -le $Amount; $i++) {

                $IP = Get-RandomIP

                Write-Host "[$i/$Amount] scanning $IP ..." -ForegroundColor $darkGreen

                Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 250)

                $Result = Get-Random -Minimum 1 -Maximum 5

                if ($Result -eq 1) {
                    Write-Host "    -> host responded" -ForegroundColor $yellow
                }
                else {
                    Write-Host "    -> no response" -ForegroundColor DarkGray
                }
            }

            Write-Host ""
            Write-Type "scan complete." 30
        }

        "2" {
            $IP = Get-RandomIP

            Write-Host ""
            Write-Host "random ip:" -ForegroundColor $cyan
            Write-Host $IP -ForegroundColor $green
        }

        "3" {
            Clear-Host

            Write-Type "initializing system scan..."
            Show-Progress "checking system files"
            Show-Progress "checking network configuration"
            Show-Progress "checking running processes"

            Write-Host ""
            Write-Host "scan results" -ForegroundColor $cyan
            Write-Host "--------------------------------"

            Write-Host "CPU usage:     $((Get-Random -Minimum 10 -Maximum 90))%"
            Write-Host "Memory usage:  $((Get-Random -Minimum 20 -Maximum 90))%"
            Write-Host "Processes:     $((Get-Random -Minimum 80 -Maximum 250))"
            Write-Host "Network:       ONLINE" -ForegroundColor $green

            Write-Host ""
            Write-Type "system scan complete."
        }

        "4" {
            Clear-Host

            Write-Host "========== SYSTEM INFO ==========" -ForegroundColor $cyan
            Write-Host ""

            Write-Host "Computer:      $env:COMPUTERNAME"
            Write-Host "User:          $env:USERNAME"
            Write-Host "OS:            $([Environment]::OSVersion.VersionString)"
            Write-Host "PowerShell:    $($PSVersionTable.PSVersion)"
            Write-Host "Architecture:  $env:PROCESSOR_ARCHITECTURE"

            Write-Host ""
        }

        "5" {
            Write-Type "closing terminal..."
            Start-Sleep -Seconds 1

            Write-Host ""
            Write-Host "goodbye." -ForegroundColor $green

            exit
        }

        default {
            Write-Host "Unknown option." -ForegroundColor $red
        }
    }
}
