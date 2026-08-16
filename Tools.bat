@echo off
setlocal

set "PSFILE=%TEMP%\tools_menu_%RANDOM%.ps1"

more +12 "%~f0" > "%PSFILE%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PSFILE%"

del "%PSFILE%" >nul 2>&1
endlocal
exit /b

$mainItems = @(
    "Network",
    "System",
    "Disk / System Health",
    "Exit"
)

$selected = 0

[Console]::CursorVisible = $false


# ============================================================
# CLEAN OUTPUT
# ============================================================

function Clean-Output {
    param (
        [object[]]$Lines
    )

    $result = @()
    $previousBlank = $false

    foreach ($line in $Lines) {

        $text = [string]$line

        if ([string]::IsNullOrWhiteSpace($text)) {

            if (-not $previousBlank) {
                $result += ""
            }

            $previousBlank = $true
        }
        else {

            $result += $text
            $previousBlank = $false
        }
    }

    return $result
}


# ============================================================
# MENU
# ============================================================

function Show-Menu {
    param (
        [string]$Title,
        [array]$Items,
        [int]$Selected
    )

    Clear-Host

    Write-Host $Title -ForegroundColor Cyan
    Write-Host

    $width = 30

    for ($i = 0; $i -lt $Items.Count; $i++) {

        $text = [string]$Items[$i]

        $padding = $width - $text.Length

        if ($padding -lt 0) {
            $padding = 0
        }

        $left = [math]::Floor($padding / 2)
        $right = $padding - $left

        $line =
            "[" +
            (" " * $left) +
            $text +
            (" " * $right) +
            "]"

        if ($i -eq $Selected) {

            Write-Host $line `
                -BackgroundColor DarkCyan `
                -ForegroundColor White
        }
        else {

            Write-Host $line `
                -ForegroundColor Gray
        }
    }
}


# ============================================================
# SAVE RESULT
# Y/N + ENTER
# ============================================================

function Save-Result {
    param (
        [string]$Title,
        [object[]]$Content,
        [string]$Prefix
    )

    Write-Host

    $answer = Read-Host "Save results to TXT? [Y/N]"

    if (
        $answer -eq "y" -or
        $answer -eq "Y"
    ) {

        $now = Get-Date

        $date = $now.ToString("M-d-yyyy")
        $fileTime = $now.ToString("hh-mm-ss-tt")

        $filename = "${Prefix}_${date}_${fileTime}.txt"

        $path = Join-Path `
            (Get-Location) `
            $filename

        $cleanContent = Clean-Output $Content

        $log = @()

        $log += $Title
        $log += ("=" * $Title.Length)
        $log += ""

        $log += (
            "Extraction date: " +
            $date +
            "  time " +
            $now.ToString("h:mm tt")
        )

        $log += ""

        $log += $cleanContent

        $log = Clean-Output $log

        $log | Set-Content `
            -Path $path `
            -Encoding UTF8

        Write-Host
        Write-Host "Saved to:" -ForegroundColor Cyan
        Write-Host $path -ForegroundColor Green
    }

    Write-Host

    Write-Host `
        "Press any key to return..." `
        -ForegroundColor DarkGray

    $null = [Console]::ReadKey($true)
}


# ============================================================
# NETWORK MENU
# ============================================================

function Network-Menu {

    $items = @(
        "ipconfig",
        "ping",
        "traceroute",
        "Back"
    )

    $selected = 0

    while ($true) {

        Show-Menu `
            -Title "NETWORK" `
            -Items $items `
            -Selected $selected

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {

            "UpArrow" {

                $selected--

                if ($selected -lt 0) {
                    $selected = $items.Count - 1
                }
            }

            "DownArrow" {

                $selected++

                if ($selected -ge $items.Count) {
                    $selected = 0
                }
            }

            "Enter" {

                switch ($selected) {

                    # ====================================================
                    # IPCONFIG
                    # ====================================================

                    0 {

                        Clear-Host

                        Write-Host "IPCONFIG" `
                            -ForegroundColor Cyan

                        Write-Host

                        $result = @(ipconfig)

                        $result = Clean-Output $result

                        foreach ($line in $result) {
                            Write-Host $line
                        }

                        Save-Result `
                            -Title "IP Configuration Diagnostic" `
                            -Content $result `
                            -Prefix "ipconfig"
                    }


                    # ====================================================
                    # PING
                    # ====================================================

                    1 {

                        Clear-Host

                        Write-Host "PING" `
                            -ForegroundColor Cyan

                        Write-Host

                        $target = Read-Host "Enter hostname or IP"

                        if (
                            ![string]::IsNullOrWhiteSpace(
                                $target
                            )
                        ) {

                            Write-Host

                            $result = @()
                            $previousBlank = $false

                            ping $target |
                            ForEach-Object {

                                $line = $_.ToString()

                                if (
                                    $line -match
                                    "^Pinging\s+.+\.\.\.$"
                                ) {
                                    return
                                }

                                if (
                                    [string]::IsNullOrWhiteSpace(
                                        $line
                                    )
                                ) {

                                    if (-not $previousBlank) {

                                        Write-Host
                                        $result += ""
                                    }

                                    $previousBlank = $true
                                }
                                else {

                                    Write-Host $line

                                    $result += $line

                                    $previousBlank = $false
                                }
                            }

                            Save-Result `
                                -Title "Ping Diagnostic" `
                                -Content $result `
                                -Prefix "ping"
                        }
                    }


                    # ====================================================
                    # TRACEROUTE
                    # ====================================================

                    2 {

                        Clear-Host

                        Write-Host "TRACEROUTE" `
                            -ForegroundColor Cyan

                        Write-Host

                        $target = Read-Host "Enter network"

                        if (
                            ![string]::IsNullOrWhiteSpace(
                                $target
                            )
                        ) {

                            Write-Host

                            $now = Get-Date

                            $date = $now.ToString("M-d-yyyy")
                            $time = $now.ToString("h:mm tt")

                            $lines = @()

                            $ok = 0
                            $warn = 0
                            $fail = 0

                            tracert $target |
                            ForEach-Object {

                                $line = $_.ToString()

                                if (
                                    $line -match
                                    "^Trace complete\.$"
                                ) {
                                    return
                                }

                                if (
                                    $line.Trim() -eq ""
                                ) {
                                    return
                                }

                                $lines += $line

                                if (
                                    ($line -match
                                        "Tracing route to") -or
                                    ($line -match
                                        "over a maximum")
                                ) {

                                    Write-Host "[ OK ] " `
                                        -ForegroundColor White `
                                        -NoNewline

                                    Write-Host $line `
                                        -ForegroundColor White
                                }

                                elseif (
                                    $line -match
                                    "\*\s+\*\s+\*"
                                ) {

                                    Write-Host "[FAIL] " `
                                        -ForegroundColor Red `
                                        -NoNewline

                                    Write-Host $line `
                                        -ForegroundColor Red

                                    $fail++
                                }

                                elseif (
                                    $line -match "\*"
                                ) {

                                    Write-Host "[WARN] " `
                                        -ForegroundColor Yellow `
                                        -NoNewline

                                    Write-Host $line `
                                        -ForegroundColor Yellow

                                    $warn++
                                }

                                elseif (
                                    $line -match "^\s*\d+"
                                ) {

                                    Write-Host "[ OK ] " `
                                        -ForegroundColor Green `
                                        -NoNewline

                                    Write-Host $line `
                                        -ForegroundColor Green

                                    $ok++
                                }

                                else {

                                    Write-Host $line
                                }
                            }

                            Write-Host

                            Write-Host "Trace complete." `
                                -ForegroundColor White

                            Write-Host

                            if (
                                ($warn -eq 0) -and
                                ($fail -eq 0)
                            ) {

                                Write-Host `
                                    "STATUS  : HEALTHY" `
                                    -ForegroundColor Green

                                $status = "HEALTHY"
                            }
                            else {

                                if ($warn -gt 0) {

                                    Write-Host `
                                        ("WARNING : " + $warn) `
                                        -ForegroundColor Yellow
                                }

                                if ($fail -gt 0) {

                                    Write-Host `
                                        ("ERROR   : " + $fail) `
                                        -ForegroundColor Red
                                }

                                Write-Host

                                if ($fail -gt 0) {

                                    Write-Host `
                                        "STATUS  : ROUTE HAS ERRORS" `
                                        -ForegroundColor Red

                                    $status = "ROUTE HAS ERRORS"
                                }
                                else {

                                    Write-Host `
                                        "STATUS  : ROUTE HAS WARNINGS" `
                                        -ForegroundColor Yellow

                                    $status = "ROUTE HAS WARNINGS"
                                }
                            }

                            Write-Host

                            Write-Host `
                                ("Extraction date: " +
                                $date +
                                "  time " +
                                $time) `
                                -ForegroundColor Cyan

                            $log = @(
                                "Network Trace Diagnostic"
                                "========================"
                                "Target: $target"
                                "Extraction date: $date  time $time"
                                ""
                            )

                            $log += $lines
                            $log += ""
                            $log += "Trace complete."
                            $log += ""

                            if (
                                ($warn -eq 0) -and
                                ($fail -eq 0)
                            ) {

                                $log += "STATUS  : HEALTHY"
                            }
                            else {

                                if ($warn -gt 0) {
                                    $log += "WARNING : $warn"
                                }

                                if ($fail -gt 0) {
                                    $log += "ERROR   : $fail"
                                }

                                $log += ""
                                $log += "STATUS  : $status"
                            }

                            $log += ""
                            $log += `
                                "Extraction date: $date  time $time"

                            $log = Clean-Output $log

                            Save-Result `
                                -Title "Network Trace Diagnostic" `
                                -Content $log `
                                -Prefix "traced_route"
                        }
                    }


                    # ====================================================
                    # BACK
                    # ====================================================

                    3 {
                        return
                    }
                }
            }
        }
    }
}


# ============================================================
# SYSTEM MENU
# ============================================================

function System-Menu {

    $items = @(
        "System Information",
        "Back"
    )

    $selected = 0

    while ($true) {

        Show-Menu `
            -Title "SYSTEM" `
            -Items $items `
            -Selected $selected

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {

            "UpArrow" {

                $selected--

                if ($selected -lt 0) {
                    $selected = $items.Count - 1
                }
            }

            "DownArrow" {

                $selected++

                if ($selected -ge $items.Count) {
                    $selected = 0
                }
            }

            "Enter" {

                switch ($selected) {

                    # ====================================================
                    # SYSTEM INFORMATION
                    # ====================================================

                    0 {

                        Clear-Host

                        Write-Host `
                            "SYSTEM INFORMATION" `
                            -ForegroundColor Cyan

                        Write-Host


                        # ------------------------------------------------
                        # START SYSTEM INFORMATION JOB
                        # ------------------------------------------------

                        $loadingJob = Start-Job -ScriptBlock {

                            $os = Get-CimInstance `
                                Win32_OperatingSystem

                            $windows = Get-ItemProperty `
                                "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"


                            # Windows edition

                            $edition = $windows.ProductName

                            if (
                                [string]::IsNullOrWhiteSpace(
                                    $edition
                                )
                            ) {
                                $edition = "Unknown"
                            }


                            # Windows release

                            $release = $windows.DisplayVersion

                            if (
                                [string]::IsNullOrWhiteSpace(
                                    $release
                                )
                            ) {
                                $release = $windows.ReleaseId
                            }

                            if (
                                [string]::IsNullOrWhiteSpace(
                                    $release
                                )
                            ) {
                                $release = "Unknown"
                            }


                            # Build

                            $build = $windows.CurrentBuildNumber

                            if (
                                [string]::IsNullOrWhiteSpace(
                                    $build
                                )
                            ) {
                                $build = $windows.CurrentBuild
                            }

                            $ubr = $windows.UBR

                            if ($null -ne $ubr) {
                                $fullBuild = "$build.$ubr"
                            }
                            else {
                                $fullBuild = $build
                            }

                            if (
                                [string]::IsNullOrWhiteSpace(
                                    $fullBuild
                                )
                            ) {
                                $fullBuild = "Unknown"
                            }


                            # Architecture

                            $architecture = $os.OSArchitecture

                            if (
                                [string]::IsNullOrWhiteSpace(
                                    $architecture
                                )
                            ) {
                                $architecture = "Unknown"
                            }


                            # Latest Windows update

                            $updateDate = "Unknown"
                            $updateKB = "Unknown"

                            try {

                                $update =
                                    Get-HotFix `
                                        -ErrorAction SilentlyContinue |
                                    Where-Object {
                                        $_.InstalledOn -ne $null
                                    } |
                                    Sort-Object {
                                        try {
                                            [datetime]$_.InstalledOn
                                        }
                                        catch {
                                            [datetime]::MinValue
                                        }
                                    } -Descending |
                                    Select-Object -First 1

                                if ($update) {

                                    if ($update.HotFixID) {
                                        $updateKB = $update.HotFixID
                                    }

                                    if ($update.InstalledOn) {

                                        try {

                                            $updateDate =
                                                ([datetime]$update.InstalledOn).ToString(
                                                    "MMMM d, yyyy"
                                                )
                                        }
                                        catch {

                                            $updateDate =
                                                [string]$update.InstalledOn
                                        }
                                    }
                                }
                            }
                            catch {

                                $updateDate = "Unknown"
                                $updateKB = "Unknown"
                            }


                            # Activation

                            $activation = "Unknown"

                            try {

                                $license =
                                    Get-CimInstance `
                                        -ClassName SoftwareLicensingProduct `
                                        -ErrorAction SilentlyContinue |
                                    Where-Object {

                                        $_.ApplicationID -eq
                                        "55c92734-d682-4d71-983e-d6ec3f16059f" -and

                                        $_.PartialProductKey -and

                                        $_.LicenseStatus -eq 1

                                    } |
                                    Select-Object -First 1

                                if ($license) {
                                    $activation = "Activated"
                                }
                                else {
                                    $activation = "Not Activated"
                                }
                            }
                            catch {

                                $activation = "Unknown"
                            }


                            [PSCustomObject]@{

                                Edition      = $edition
                                Release      = $release
                                Build        = $fullBuild
                                UpdateDate   = $updateDate
                                UpdateKB     = $updateKB
                                Architecture = $architecture
                                Activation   = $activation
                            }
                        }


                        # ------------------------------------------------
                        # ONE-LINE LOADING ANIMATION
                        # ------------------------------------------------

                        $frame = 0

                        $loaderRow = [Console]::CursorTop

                        while (
                            $loadingJob.State -eq "Running"
                        ) {

                            [Console]::SetCursorPosition(
                                0,
                                $loaderRow
                            )

                            Write-Host "[" `
                                -NoNewline `
                                -ForegroundColor DarkGray


                            if ($frame -eq 0) {

                                Write-Host "*" `
                                    -NoNewline `
                                    -ForegroundColor Red

                                Write-Host " " `
                                    -NoNewline

                                Write-Host "*" `
                                    -NoNewline `
                                    -ForegroundColor DarkRed

                                Write-Host " " `
                                    -NoNewline

                                Write-Host "*" `
                                    -NoNewline `
                                    -ForegroundColor DarkRed
                            }

                            elseif ($frame -eq 1) {

                                Write-Host "*" `
                                    -NoNewline `
                                    -ForegroundColor DarkRed

                                Write-Host " " `
                                    -NoNewline

                                Write-Host "*" `
                                    -NoNewline `
                                    -ForegroundColor Red

                                Write-Host " " `
                                    -NoNewline

                                Write-Host "*" `
                                    -NoNewline `
                                    -ForegroundColor DarkRed
                            }

                            else {

                                Write-Host "*" `
                                    -NoNewline `
                                    -ForegroundColor DarkRed

                                Write-Host " " `
                                    -NoNewline

                                Write-Host "*" `
                                    -NoNewline `
                                    -ForegroundColor DarkRed

                                Write-Host " " `
                                    -NoNewline

                                Write-Host "*" `
                                    -NoNewline `
                                    -ForegroundColor Red
                            }


                            Write-Host "]" `
                                -NoNewline `
                                -ForegroundColor DarkGray

                            Write-Host "   " `
                                -NoNewline


                            $frame++

                            if ($frame -ge 3) {
                                $frame = 0
                            }


                            Start-Sleep `
                                -Milliseconds 180
                        }


                        # ------------------------------------------------
                        # RECEIVE INFORMATION
                        # ------------------------------------------------

                        $info =
                            Receive-Job `
                                $loadingJob `
                                -ErrorAction SilentlyContinue

                        Remove-Job `
                            $loadingJob `
                            -Force `
                            -ErrorAction SilentlyContinue


                        # ------------------------------------------------
                        # CLEAR LOADER
                        # ------------------------------------------------

                        [Console]::SetCursorPosition(
                            0,
                            $loaderRow
                        )

                        Write-Host `
                            (" " * 30)

                        [Console]::SetCursorPosition(
                            0,
                            $loaderRow
                        )


                        # ------------------------------------------------
                        # DISPLAY INFORMATION
                        # ------------------------------------------------

                        if ($info) {

                            $result = @(
                                "Windows Version : $($info.Edition)"
                                "Release         : $($info.Release)"
                                "OS Build        : $($info.Build)"
                                "Last Update     : $($info.UpdateDate)"
                                "Update          : $($info.UpdateKB)"
                                "Architecture    : $($info.Architecture)"
                                "Activation      : $($info.Activation)"
                            )
                        }
                        else {

                            $result = @(
                                "Windows Version : Unknown"
                                "Release         : Unknown"
                                "OS Build        : Unknown"
                                "Last Update     : Unknown"
                                "Update          : Unknown"
                                "Architecture    : Unknown"
                                "Activation      : Unknown"
                            )
                        }


                        $result =
                            Clean-Output $result


                        foreach ($line in $result) {

                            if (
                                $line -match
                                "Activation\s+: Activated"
                            ) {

                                Write-Host $line `
                                    -ForegroundColor Green
                            }

                            elseif (
                                $line -match
                                "Activation\s+: Not Activated"
                            ) {

                                Write-Host $line `
                                    -ForegroundColor Red
                            }

                            else {

                                Write-Host $line `
                                    -ForegroundColor White
                            }
                        }


                        Write-Host

                        Write-Host `
                            "Press any key to return..." `
                            -ForegroundColor DarkGray

                        $null =
                            [Console]::ReadKey($true)
                    }


                    # ====================================================
                    # BACK
                    # ====================================================

                    1 {
                        return
                    }
                }
            }
        }
    }
}


# ============================================================
# DISK / SYSTEM HEALTH MENU
# ============================================================

function Disk-Menu {

    $items = @(
        "Disk Space",
        "SFC /scannow",
        "Back"
    )

    $selected = 0

    while ($true) {

        Show-Menu `
            -Title "DISK / SYSTEM HEALTH" `
            -Items $items `
            -Selected $selected

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {

            "UpArrow" {

                $selected--

                if ($selected -lt 0) {
                    $selected = $items.Count - 1
                }
            }

            "DownArrow" {

                $selected++

                if ($selected -ge $items.Count) {
                    $selected = 0
                }
            }

            "Enter" {

                switch ($selected) {

                    # ====================================================
                    # DISK SPACE
                    # ====================================================

                    0 {

                        Clear-Host

                        Write-Host "DISK SPACE" `
                            -ForegroundColor Cyan

                        Write-Host

                        $drives =
                            Get-PSDrive `
                                -PSProvider FileSystem |
                            Where-Object {
                                $_.Used -ne $null
                            }

                        $result = @()

                        foreach ($drive in $drives) {

                            $used =
                                [math]::Round(
                                    $drive.Used / 1GB,
                                    2
                                )

                            $free =
                                [math]::Round(
                                    $drive.Free / 1GB,
                                    2
                                )

                            $total =
                                [math]::Round(
                                    (
                                        $drive.Used +
                                        $drive.Free
                                    ) / 1GB,
                                    2
                                )

                            $line =
                                "Drive $($drive.Name):  " +
                                "Used $used GB  |  " +
                                "Free $free GB  |  " +
                                "Total $total GB"

                            $result += $line

                            Write-Host $line
                        }


                        Write-Host

                        Write-Host `
                            "Press any key to return..." `
                            -ForegroundColor DarkGray

                        $null =
                            [Console]::ReadKey($true)
                    }


                    # ====================================================
                    # SFC / SCANNOW
                    # ====================================================

                    1 {

                        Clear-Host

                        Write-Host "SFC / SCANNOW" `
                            -ForegroundColor Cyan

                        Write-Host

                        Write-Host `
                            "Checking Windows system files..." `
                            -ForegroundColor Yellow

                        Write-Host

                        # Run SFC in real time
                        sfc /scannow

                        Write-Host

                        Write-Host `
                            "Press any key to return..." `
                            -ForegroundColor DarkGray

                        $null =
                            [Console]::ReadKey($true)
                    }


                    # ====================================================
                    # BACK
                    # ====================================================

                    2 {
                        return
                    }
                }
            }
        }
    }
}


# ============================================================
# MAIN MENU
# ============================================================

try {

    while ($true) {

        Show-Menu `
            -Title "TOOLS" `
            -Items $mainItems `
            -Selected $selected

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {

            "UpArrow" {

                $selected--

                if ($selected -lt 0) {
                    $selected = $mainItems.Count - 1
                }
            }

            "DownArrow" {

                $selected++

                if ($selected -ge $mainItems.Count) {
                    $selected = 0
                }
            }

            "Enter" {

                switch ($selected) {

                    0 {
                        Network-Menu
                    }

                    1 {
                        System-Menu
                    }

                    2 {
                        Disk-Menu
                    }

                    3 {

                        Clear-Host

                        [Console]::CursorVisible = $true

                        exit
                    }
                }
            }
        }
    }
}
finally {

    [Console]::CursorVisible = $true
}
