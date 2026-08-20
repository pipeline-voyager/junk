# powershell tui

$Host.UI.RawUI.WindowTitle = "PowerShell Terminal"

$menu = @(
    "Dashboard"
    "IP Generator"
    "Network Scan"
    "System Info"
    "Settings"
    "Exit"
)

$selected = 0
$running = $true

function Hide-Cursor {
    try {
        [Console]::CursorVisible = $false
    }
    catch {}
}

function Show-Cursor {
    try {
        [Console]::CursorVisible = $true
    }
    catch {}
}

function Clear-Screen {
    [Console]::Clear()
}

function Write-At {
    param (
        [int]$X,
        [int]$Y,
        [string]$Text,
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    try {
        [Console]::SetCursorPosition($X, $Y)
        Write-Host $Text -ForegroundColor $Color -NoNewline
    }
    catch {}
}

function Get-RandomIP {

    do {
        $a = Get-Random -Minimum 1 -Maximum 224
        $b = Get-Random -Minimum 0 -Maximum 256
        $c = Get-Random -Minimum 0 -Maximum 256
        $d = Get-Random -Minimum 1 -Maximum 255

        $private =
            ($a -eq 10) -or
            ($a -eq 127) -or
            ($a -eq 169 -and $b -eq 254) -or
            ($a -eq 192 -and $b -eq 168) -or
            ($a -eq 172 -and $b -ge 16 -and $b -le 31) -or
            ($a -eq 0) -or
            ($a -ge 224)

    } while ($private)

    return "$a.$b.$c.$d"
}

function Draw-Header {

    $width = [Console]::WindowWidth

    Write-At 0 0 ("=" * $width) DarkCyan
    Write-At 2 1 "DIY TERMINAL" Cyan

    $time = Get-Date -Format "HH:mm:ss"

    if ($width -gt 25) {
        Write-At ($width - 12) 1 $time DarkGray
    }

    Write-At 0 2 ("=" * $width) DarkCyan
}

function Draw-Sidebar {

    $width = 24
    $height = [Console]::WindowHeight

    for ($y = 3; $y -lt ($height - 2); $y++) {
        Write-At 0 $y (" " * $width) DarkGray
    }

    Write-At 3 4 "MAIN" DarkCyan

    for ($i = 0; $i -lt $menu.Count; $i++) {

        $y = 6 + $i

        if ($i -eq $selected) {

            $text = "> " + $menu[$i].PadRight(18)

            try {
                [Console]::SetCursorPosition(2, $y)
                Write-Host $text -BackgroundColor Cyan -ForegroundColor Black -NoNewline
            }
            catch {}
        }
        else {

            Write-At 2 $y ("  " + $menu[$i].PadRight(18)) Gray
        }
    }

    Write-At 3 ($height - 5) "UP/DOWN  Navigate" DarkGray
    Write-At 3 ($height - 4) "ENTER    Select" DarkGray
    Write-At 3 ($height - 3) "Q        Quit" DarkGray
}

function Draw-Dashboard {

    $x = 28

    Write-At $x 5 "DASHBOARD" White

    Write-At $x 7 "SYSTEM" DarkCyan
    Write-At $x 8 "Computer      $env:COMPUTERNAME"
    Write-At $x 9 "User          $env:USERNAME"
    Write-At $x 10 "PowerShell    $($PSVersionTable.PSVersion)"

    Write-At $x 12 "NETWORK" DarkCyan
    Write-At $x 13 "Status        ONLINE" Green
    Write-At $x 14 "Random IP     $(Get-RandomIP)"

    Write-At $x 16 "STATUS" DarkCyan
    Write-At $x 17 "Terminal      READY" Green
    Write-At $x 18 "Mode          SIMULATION" Yellow
}

function Draw-Frame {

    Clear-Screen

    Draw-Header
    Draw-Sidebar
    Draw-Dashboard

    $height = [Console]::WindowHeight
    $width = [Console]::WindowWidth

    Write-At 0 ($height - 1) ("=" * $width) DarkCyan
}

function Wait-Key {

    $y = [Console]::WindowHeight - 4

    Write-At 28 $y "Press any key to continue..." DarkGray

    [Console]::ReadKey($true) | Out-Null
}

function IP-Generator {

    Clear-Screen

    $x = 28

    Write-At $x 4 "IP GENERATOR" Cyan
    Write-At $x 6 "How many IPs do you want?" White

    [Console]::SetCursorPosition($x, 7)
    $amountInput = Read-Host

    $amount = 0

    if (-not [int]::TryParse($amountInput, [ref]$amount)) {
        Write-At $x 9 "Invalid number." Red
        Wait-Key
        return
    }

    if ($amount -lt 1) {
        Write-At $x 9 "Invalid number." Red
        Wait-Key
        return
    }

    Write-At $x 9 "Generating $amount IPs..." Yellow

    $results = [System.Collections.Generic.List[string]]::new()

    for ($i = 0; $i -lt $amount; $i++) {

        $ip = Get-RandomIP
        $cidr = Get-Random -Minimum 8 -Maximum 33

        $entry = "$ip/$cidr"

        $results.Add($entry)

        if ($i -lt 15) {
            Write-At $x (11 + $i) $entry Green
        }

        Start-Sleep -Milliseconds 20
    }

    $file = "random_ips.txt"

    $results | Set-Content -Path $file

    Write-At $x 28 "Generated: $amount" Green
    Write-At $x 29 "Saved to:  $file" Green

    Wait-Key
}

function Network-Scan {

    Clear-Screen

    $x = 28

    Write-At $x 4 "NETWORK SCAN" Cyan
    Write-At $x 6 "SIMULATION MODE" Yellow

    for ($i = 1; $i -le 20; $i++) {

        $ip = Get-RandomIP

        Write-At $x 8 ("[{0}/20] scanning {1}..." -f $i, $ip)

        Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 200)

        if ((Get-Random -Minimum 0 -Maximum 5) -eq 1) {
            Write-At $x 8 ("[{0}/20] {1}  HOST FOUND" -f $i, $ip) Green
        }
        else {
            Write-At $x 8 ("[{0}/20] {1}  NO RESPONSE" -f $i, $ip) DarkGray
        }
    }

    Write-At $x 11 "Scan complete." Green

    Wait-Key
}

function System-Info {

    Clear-Screen

    $x = 28

    Write-At $x 4 "SYSTEM INFORMATION" Cyan

    Write-At $x 7 "Computer       $env:COMPUTERNAME"
    Write-At $x 8 "User           $env:USERNAME"
    Write-At $x 9 "OS             $([Environment]::OSVersion.VersionString)"
    Write-At $x 10 "PowerShell     $($PSVersionTable.PSVersion)"
    Write-At $x 11 "Architecture   $env:PROCESSOR_ARCHITECTURE"

    try {

        $memory = Get-CimInstance Win32_OperatingSystem

        $total = [math]::Round(
            $memory.TotalVisibleMemorySize / 1MB,
            2
        )

        $free = [math]::Round(
            $memory.FreePhysicalMemory / 1MB,
            2
        )

        $used = [math]::Round(
            $total - $free,
            2
        )

        Write-At $x 13 "Memory Total   $total GB"
        Write-At $x 14 "Memory Used    $used GB"
    }
    catch {

        Write-At $x 13 "Memory         unavailable" Yellow
    }

    Wait-Key
}

function Settings {

    Clear-Screen

    $x = 28

    Write-At $x 4 "SETTINGS" Cyan

    Write-At $x 7 "Theme          Cyan / Dark"
    Write-At $x 8 "Mode           Simulation"
    Write-At $x 9 "Animations     Enabled"

    Write-At $x 12 "Settings are currently read-only." DarkGray

    Wait-Key
}

Hide-Cursor

try {

    while ($running) {

        Draw-Frame

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {

            "UpArrow" {

                $selected--

                if ($selected -lt 0) {
                    $selected = $menu.Count - 1
                }
            }

            "DownArrow" {

                $selected++

                if ($selected -ge $menu.Count) {
                    $selected = 0
                }
            }

            "Enter" {

                switch ($menu[$selected]) {

                    "Dashboard" {
                    }

                    "IP Generator" {
                        IP-Generator
                    }

                    "Network Scan" {
                        Network-Scan
                    }

                    "System Info" {
                        System-Info
                    }

                    "Settings" {
                        Settings
                    }

                    "Exit" {
                        $running = $false
                    }
                }
            }

            "Q" {
                $running = $false
            }
        }
    }
}
finally {

    Show-Cursor
    Clear-Screen

    Write-Host "Terminal closed." -ForegroundColor Cyan
}
