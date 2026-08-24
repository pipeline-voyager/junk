#requires -Version 5.1

<#
===========================================================================
                    WINDOWS ADMIN TOOLBOX
===========================================================================

Version: 1

CONTROLS
---------------------------------------------------------------------------
UP / DOWN       Navigate
ENTER           Select
ESC             Back one level
Q               Quit
R               Refresh

INPUT
---------------------------------------------------------------------------
ENTER           Accept
ESC             Back
BACKSPACE       Delete

===========================================================================

IMPORTANT
-----------
Run PowerShell as Administrator for SFC, DISM, CHKDSK, user management,
network resets and other administrative operations.

=========================================================================== 
#>

Set-StrictMode -Version 2
$ErrorActionPreference = "SilentlyContinue"

# =========================================================================
# GLOBAL SETTINGS
# =========================================================================

$script:AppName = "WINDOWS ADMIN TOOLBOX"
$script:Version = "5.1"

$script:NormalForeground = "Gray"
$script:NormalBackground = "Black"

$script:HighlightForeground = "Black"
$script:HighlightBackground = "White"

$script:TitleForeground = "White"
$script:MutedForeground = "DarkGray"

$script:SuccessColor = "Green"
$script:WarningColor = "Yellow"
$script:ErrorColor = "Red"

# =========================================================================
# ADMINISTRATOR CHECK
# =========================================================================

function Test-IsAdministrator {

    try {

        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()

        $principal = New-Object Security.Principal.WindowsPrincipal($identity)

        return $principal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
    }
    catch {

        return $false
    }
}

$script:IsAdmin = Test-IsAdministrator

# =========================================================================
# TERMINAL FUNCTIONS
# =========================================================================

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

    Clear-Host
    Hide-Cursor
}

function Get-TerminalWidth {

    try {

        $width = [Console]::WindowWidth

        if ($width -lt 80) {
            return 80
        }

        return $width
    }
    catch {

        return 100
    }
}

# =========================================================================
# STATUS
# =========================================================================

function Get-PrimaryIPv4 {

    try {

        $config = Get-NetIPConfiguration |
            Where-Object {
                $_.IPv4DefaultGateway -and
                $_.IPv4Address
            } |
            Select-Object -First 1

        if ($config) {

            return $config.IPv4Address.IPAddress
        }
    }
    catch {}

    return "N/A"
}

function Get-PrimaryGateway {

    try {

        $config = Get-NetIPConfiguration |
            Where-Object {
                $_.IPv4DefaultGateway
            } |
            Select-Object -First 1

        if ($config) {

            return $config.IPv4DefaultGateway.NextHop
        }
    }
    catch {}

    return "N/A"
}

function Get-PrimaryDNS {

    try {

        $dns = Get-DnsClientServerAddress `
            -AddressFamily IPv4 |
            Where-Object {
                $_.ServerAddresses
            } |
            Select-Object -First 1

        if ($dns) {

            return (
                $dns.ServerAddresses -join ", "
            )
        }
    }
    catch {}

    return "N/A"
}

function Get-Uptime {

    try {

        $os = Get-CimInstance Win32_OperatingSystem

        $boot = $os.LastBootUpTime

        $span = (Get-Date) - $boot

        return (
            "{0}d {1}h {2}m" -f
            $span.Days,
            $span.Hours,
            $span.Minutes
        )
    }
    catch {

        return "N/A"
    }
}

function Get-FirewallStatus {

    try {

        $profiles = Get-NetFirewallProfile

        $disabled = @(
            $profiles |
            Where-Object {
                $_.Enabled -eq $false
            }
        )

        if ($disabled.Count -eq 0) {

            return "ON"
        }

        return "PARTIAL/OFF"
    }
    catch {

        return "UNKNOWN"
    }
}

function Show-StatusBar {

    $hostname = $env:COMPUTERNAME
    $username = $env:USERNAME

    if ($script:IsAdmin) {

        $privilege = "ADMIN"
    }
    else {

        $privilege = "STANDARD USER"
    }

    Write-Host (
        "Host: {0} | User: {1} | {2}" -f
        $hostname,
        $username,
        $privilege
    ) -ForegroundColor DarkGray
}

# =========================================================================
# HEADER
# =========================================================================

function Show-Header {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Clear-Screen

    Write-Host ""
    Write-Host $Title -ForegroundColor White

    Write-Host (
        "-" * $Title.Length
    ) -ForegroundColor DarkGray

    Write-Host ""

    Show-StatusBar

    Write-Host ""
}

# =========================================================================
# FOOTER
# =========================================================================

function Show-Footer {

    Write-Host ""

    Write-Host (
        "UP/DOWN Navigate | ENTER Select | ESC Back | Q Quit | R Refresh"
    ) -ForegroundColor DarkGray
}

# =========================================================================
# PAUSE
# =========================================================================

function Pause-Screen {

    Write-Host ""

    Write-Host (
        "Press any key to continue..."
    ) -ForegroundColor DarkGray

    try {

        [Console]::ReadKey($true) | Out-Null
    }
    catch {

        Read-Host | Out-Null
    }
}

# =========================================================================
# CUSTOM INPUT
# =========================================================================

function Read-TUIInput {

    param(
        [string]$Prompt,
        [string]$Default = ""
    )

    Show-Cursor

    Write-Host $Prompt -NoNewline -ForegroundColor White

    $text = $Default

    if ($Default.Length -gt 0) {

        Write-Host $Default -NoNewline
    }

    while ($true) {

        try {

            $key = [Console]::ReadKey($true)
        }
        catch {

            Hide-Cursor
            return $null
        }

        switch ($key.Key) {

            "Escape" {

                Hide-Cursor
                return $null
            }

            "Enter" {

                Write-Host ""

                Hide-Cursor

                return $text
            }

            "Backspace" {

                if ($text.Length -gt 0) {

                    $text = $text.Substring(
                        0,
                        $text.Length - 1
                    )

                    Write-Host "`b `b" -NoNewline
                }

                continue
            }

            default {

                if (
                    -not [char]::IsControl(
                        $key.KeyChar
                    )
                ) {

                    $text += $key.KeyChar

                    Write-Host `
                        $key.KeyChar `
                        -NoNewline
                }
            }
        }
    }
}

# =========================================================================
# NUMBER INPUT
# =========================================================================

function Read-TUIInteger {

    param(
        [string]$Prompt,
        [int]$Default,
        [int]$Minimum = 1,
        [int]$Maximum = 65535
    )

    while ($true) {

        $value = Read-TUIInput (
            "{0} [{1}]: " -f
            $Prompt,
            $Default
        )

        if ($null -eq $value) {

            return $null
        }

        if ([string]::IsNullOrWhiteSpace($value)) {

            return $Default
        }

        $number = 0

        if (
            [int]::TryParse(
                $value,
                [ref]$number
            )
        ) {

            if (
                $number -ge $Minimum -and
                $number -le $Maximum
            ) {

                return $number
            }
        }

        Write-Host ""

        Write-Host (
            "Enter a number from {0} to {1}." -f
            $Minimum,
            $Maximum
        ) -ForegroundColor Red

        Write-Host ""
    }
}

# =========================================================================
# CONFIRMATION
# =========================================================================

function Confirm-Action {

    param(
        [string]$Message
    )

    Write-Host ""

    Write-Host "WARNING" `
        -ForegroundColor Yellow

    Write-Host $Message `
        -ForegroundColor Yellow

    Write-Host ""

    $answer = Read-TUIInput "Continue? [Y/N]: "

    if ($null -eq $answer) {

        return $false
    }

    return (
        $answer.Trim() -match "^(Y|YES)$"
    )
}

# =========================================================================
# ADMIN REQUIREMENT
# =========================================================================

function Require-Administrator {

    param(
        [string]$Operation
    )

    if ($script:IsAdmin) {

        return $true
    }

    Write-Host ""

    Write-Host (
        "ADMINISTRATOR PRIVILEGES REQUIRED"
    ) -ForegroundColor Red

    Write-Host ""

    Write-Host (
        "'{0}' requires an elevated PowerShell window." -f
        $Operation
    ) -ForegroundColor Yellow

    Write-Host ""

    Write-Host (
        "Close this window and run PowerShell as Administrator."
    ) -ForegroundColor Gray

    Pause-Screen

    return $false
}

# =========================================================================
# DASHBOARD
# =========================================================================

function Show-Dashboard {

    Show-Header "$script:AppName v$script:Version > DASHBOARD"

    try {

        $os = Get-CimInstance Win32_OperatingSystem
        $computer = Get-CimInstance Win32_ComputerSystem

        $hostname = $env:COMPUTERNAME
        $username = $env:USERNAME

        Write-Host "SYSTEM" -ForegroundColor White
        Write-Host "------" -ForegroundColor DarkGray

        Write-Host ("Hostname       : {0}" -f $hostname)
        Write-Host ("Username       : {0}" -f $username)
        Write-Host ("Domain         : {0}" -f $computer.Domain)
        Write-Host ("Manufacturer   : {0}" -f $computer.Manufacturer)
        Write-Host ("Model          : {0}" -f $computer.Model)

        Write-Host ""

        Write-Host "WINDOWS" -ForegroundColor White
        Write-Host "-------" -ForegroundColor DarkGray

        Write-Host ("Version        : {0}" -f $os.Caption)
        Write-Host ("Version Number : {0}" -f $os.Version)
        Write-Host ("Build          : {0}" -f $os.BuildNumber)
        Write-Host ("Architecture   : {0}" -f $os.OSArchitecture)
        Write-Host ("Last Boot      : {0}" -f $os.LastBootUpTime)
        Write-Host ("Uptime         : {0}" -f (Get-Uptime))

        Write-Host ""

        Write-Host "NETWORK" -ForegroundColor White
        Write-Host "-------" -ForegroundColor DarkGray

        Write-Host ("IPv4           : {0}" -f (Get-PrimaryIPv4))
        Write-Host ("Gateway        : {0}" -f (Get-PrimaryGateway))
        Write-Host ("DNS            : {0}" -f (Get-PrimaryDNS))

        $firewall = Get-FirewallStatus

        if ($firewall -eq "ON") {

            Write-Host (
                "Firewall       : {0}" -f $firewall
            ) -ForegroundColor Green
        }
        else {

            Write-Host (
                "Firewall       : {0}" -f $firewall
            ) -ForegroundColor Yellow
        }

        Write-Host ""

        if ($script:IsAdmin) {

            Write-Host "Privileges     : ADMINISTRATOR" `
                -ForegroundColor Green
        }
        else {

            Write-Host "Privileges     : STANDARD USER" `
                -ForegroundColor Yellow
        }
    }
    catch {

        Write-Host ""

        Write-Host "Unable to retrieve some system information." `
            -ForegroundColor Yellow
    }

    Pause-Screen
}

# =========================================================================
# NETWORK - PING
# =========================================================================

function Invoke-Ping {

    Show-Header "$script:AppName > NETWORK > PING"

    $target = Read-TUIInput "Hostname or IP: "

    if ($null -eq $target) {
        return
    }

    if ([string]::IsNullOrWhiteSpace($target)) {
        return
    }

    $count = Read-TUIInteger `
        "Packet count" `
        4 `
        1 `
        100

    if ($null -eq $count) {
        return
    }

    Write-Host ""

    Write-Host (
        "Testing {0}..." -f $target
    ) -ForegroundColor White

    Write-Host ""

    try {

        $results = @(
            Test-Connection `
                -ComputerName $target `
                -Count $count `
                -ErrorAction SilentlyContinue
        )

        if ($results.Count -eq 0) {

            Write-Host (
                "NO REPLIES RECEIVED."
            ) -ForegroundColor Red
        }
        else {

            $results |
                Select-Object `
                    Address,
                    IPV4Address,
                    ResponseTime |
                Format-Table -AutoSize

            $lost = $count - $results.Count

            $loss = [Math]::Round(
                ($lost / $count) * 100,
                2
            )

            Write-Host ""

            Write-Host ("Sent        : {0}" -f $count)
            Write-Host ("Received    : {0}" -f $results.Count)
            Write-Host ("Lost        : {0}" -f $lost)

            if ($loss -eq 0) {

                Write-Host (
                    "Packet Loss : {0}%" -f $loss
                ) -ForegroundColor Green
            }
            elseif ($loss -lt 50) {

                Write-Host (
                    "Packet Loss : {0}%" -f $loss
                ) -ForegroundColor Yellow
            }
            else {

                Write-Host (
                    "Packet Loss : {0}%" -f $loss
                ) -ForegroundColor Red
            }
        }
    }
    catch {

        Write-Host ""

        Write-Host "Ping failed." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# NETWORK - TRACEROUTE
# =========================================================================

function Invoke-Tracert {

    Show-Header "$script:AppName > NETWORK > TRACEROUTE"

    $target = Read-TUIInput "Destination: "

    if ($null -eq $target) {
        return
    }

    if ([string]::IsNullOrWhiteSpace($target)) {
        return
    }

    Write-Host ""

    tracert.exe $target

    Pause-Screen
}

# =========================================================================
# NETWORK - DNS
# =========================================================================

function Invoke-DNSLookup {

    Show-Header "$script:AppName > NETWORK > DNS LOOKUP"

    $target = Read-TUIInput "Hostname: "

    if ($null -eq $target) {
        return
    }

    if ([string]::IsNullOrWhiteSpace($target)) {
        return
    }

    Write-Host ""

    try {

        Resolve-DnsName $target |
            Select-Object `
                Name,
                Type,
                TTL,
                IPAddress,
                NameHost |
            Format-Table -AutoSize
    }
    catch {

        nslookup.exe $target
    }

    Pause-Screen
}

# =========================================================================
# NETWORK - REVERSE DNS
# =========================================================================

function Invoke-ReverseDNS {

    Show-Header "$script:AppName > NETWORK > REVERSE DNS"

    $target = Read-TUIInput "IP address: "

    if ($null -eq $target) {
        return
    }

    if ([string]::IsNullOrWhiteSpace($target)) {
        return
    }

    Write-Host ""

    try {

        Resolve-DnsName `
            -Name $target `
            -Type PTR |
            Format-Table -AutoSize
    }
    catch {

        nslookup.exe $target
    }

    Pause-Screen
}

# =========================================================================
# NETWORK - PORT CHECK
# =========================================================================

function Invoke-PortCheck {

    Show-Header "$script:AppName > NETWORK > TCP PORT CHECK"

    $target = Read-TUIInput "Hostname or IP: "

    if ($null -eq $target) {
        return
    }

    if ([string]::IsNullOrWhiteSpace($target)) {
        return
    }

    $port = Read-TUIInteger `
        "TCP port" `
        443 `
        1 `
        65535

    if ($null -eq $port) {
        return
    }

    Write-Host ""

    Write-Host (
        "Testing {0}:{1}..." -f
        $target,
        $port
    ) -ForegroundColor White

    Write-Host ""

    try {

        $result = Test-NetConnection `
            -ComputerName $target `
            -Port $port `
            -InformationLevel Detailed `
            -WarningAction SilentlyContinue

        if ($result.TcpTestSucceeded) {

            Write-Host (
                "TCP {0} is OPEN." -f $port
            ) -ForegroundColor Green
        }
        else {

            Write-Host (
                "TCP {0} is CLOSED/FILTERED/UNREACHABLE." -f $port
            ) -ForegroundColor Red
        }

        Write-Host ""

        $result |
            Select-Object `
                ComputerName,
                RemoteAddress,
                RemotePort,
                InterfaceAlias,
                SourceAddress,
                TcpTestSucceeded |
            Format-List
    }
    catch {

        Write-Host ""

        Write-Host "Port test failed." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# NETWORK - ADAPTERS
# =========================================================================

function Invoke-Adapters {

    Show-Header "$script:AppName > NETWORK > ADAPTERS"

    try {

        Get-NetAdapter |
            Select-Object `
                Name,
                InterfaceDescription,
                Status,
                LinkSpeed,
                MacAddress |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "Unable to read network adapters." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# NETWORK - IP ADDRESSES
# =========================================================================

function Invoke-IPAddresses {

    Show-Header "$script:AppName > NETWORK > IP ADDRESSES"

    try {

        Get-NetIPAddress |
            Where-Object {
                $_.AddressFamily -in @(
                    "IPv4",
                    "IPv6"
                )
            } |
            Select-Object `
                InterfaceAlias,
                AddressFamily,
                IPAddress,
                PrefixLength,
                AddressState |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "Unable to read IP addresses." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# NETWORK - ROUTES
# =========================================================================

function Invoke-Routes {

    Show-Header "$script:AppName > NETWORK > ROUTING TABLE"

    try {

        Get-NetRoute |
            Sort-Object `
                AddressFamily,
                DestinationPrefix |
            Select-Object `
                AddressFamily,
                DestinationPrefix,
                NextHop,
                InterfaceAlias,
                RouteMetric,
                State |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "Unable to read routing table." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# NETWORK - ARP
# =========================================================================

function Invoke-ARP {

    Show-Header "$script:AppName > NETWORK > ARP / NEIGHBORS"

    try {

        Get-NetNeighbor |
            Select-Object `
                InterfaceAlias,
                IPAddress,
                LinkLayerAddress,
                State |
            Format-Table -AutoSize
    }
    catch {

        arp.exe -a
    }

    Pause-Screen
}

# =========================================================================
# NETWORK - NETSTAT
# =========================================================================

function Invoke-Netstat {

    Show-Header "$script:AppName > NETWORK > NETSTAT"

    $selectedProtocol = 0

    while ($true) {

        Clear-Screen

        Show-Header "$script:AppName > NETWORK > NETSTAT"

        Write-Host "SELECT PROTOCOL" -ForegroundColor White
        Write-Host "---------------" -ForegroundColor DarkGray

        Write-Host ""

        $protocols = @(
            "TCP CONNECTIONS",
            "UDP ENDPOINTS"
        )

        # =================================================================
        # FULL WIDTH NETSTAT MENU HIGHLIGHT
        # =================================================================

        $terminalWidth = Get-TerminalWidth
        $lineWidth = $terminalWidth - 1

        foreach ($index in 0..($protocols.Count - 1)) {

            $line = "  " + $protocols[$index]

            # Extend the line to the full terminal width
            if ($line.Length -lt $lineWidth) {

                $line = $line.PadRight($lineWidth)
            }
            elseif ($line.Length -gt $lineWidth) {

                $line = $line.Substring(
                    0,
                    $lineWidth
                )
            }

            # Highlight the entire row
            if ($index -eq $selectedProtocol) {

                Write-Host `
                    $line `
                    -ForegroundColor Black `
                    -BackgroundColor White
            }
            else {

                Write-Host `
                    $line `
                    -ForegroundColor Gray `
                    -BackgroundColor Black
            }
        }

        Write-Host ""

        Write-Host "[ENTER] Select | [ESC] Back" `
            -ForegroundColor DarkGray

        try {

            $key = [Console]::ReadKey($true)
        }
        catch {

            return
        }

        switch ($key.Key) {

            "UpArrow" {

                $selectedProtocol--

                if ($selectedProtocol -lt 0) {

                    $selectedProtocol =
                        $protocols.Count - 1
                }

                continue
            }

            "DownArrow" {

                $selectedProtocol++

                if ($selectedProtocol -ge $protocols.Count) {

                    $selectedProtocol = 0
                }

                continue
            }

            "Escape" {

                return
            }

            "Enter" {

                # =========================================================
                # TCP
                # =========================================================

                if ($selectedProtocol -eq 0) {

                    while ($true) {

                        Clear-Screen

                        Show-Header "$script:AppName > NETWORK > NETSTAT > TCP"

                        Write-Host ""

                        Write-Host "TCP CONNECTIONS" -ForegroundColor White
                        Write-Host "---------------" -ForegroundColor DarkGray

                        Write-Host ""

                        try {

                            $connections = @(
                                Get-NetTCPConnection |
                                    Sort-Object LocalPort, RemotePort
                            )

                            if ($connections.Count -eq 0) {

                                Write-Host "No TCP connections found." `
                                    -ForegroundColor Yellow
                            }
                            else {

                                $connections |
                                    Select-Object `
                                        State,
                                        LocalAddress,
                                        LocalPort,
                                        RemoteAddress,
                                        RemotePort,
                                        OwningProcess |
                                    Format-Table -AutoSize
                            }
                        }
                        catch {

                            Write-Host "Unable to read TCP connections." `
                                -ForegroundColor Red

                            Write-Host ""

                            netstat.exe -ano -p tcp
                        }

                        Write-Host ""

                        Write-Host "[F] Filter by TCP port | [R] Refresh | [ESC] Back" `
                            -ForegroundColor DarkGray

                        try {

                            $tcpKey = [Console]::ReadKey($true)
                        }
                        catch {

                            return
                        }

                        switch ($tcpKey.Key) {

                            "F" {

                                Write-Host ""

                                $port = Read-TUIInteger `
                                    "TCP port to filter" `
                                    443 `
                                    1 `
                                    65535

                                if ($null -eq $port) {
                                    continue
                                }

                                Show-Header `
                                    "$script:AppName > NETWORK > NETSTAT > FILTER TCP $port"

                                Write-Host ""

                                Write-Host (
                                    "Showing TCP connections where LocalPort or RemotePort = {0}" -f $port
                                ) -ForegroundColor White

                                Write-Host ""

                                try {

                                    $filtered = @(
                                        Get-NetTCPConnection |
                                            Where-Object {
                                                $_.LocalPort -eq $port -or
                                                $_.RemotePort -eq $port
                                            } |
                                            Sort-Object `
                                                State,
                                                LocalAddress,
                                                LocalPort,
                                                RemoteAddress,
                                                RemotePort
                                    )

                                    if ($filtered.Count -eq 0) {

                                        Write-Host (
                                            "No TCP connections found for port {0}." -f $port
                                        ) -ForegroundColor Yellow
                                    }
                                    else {

                                        $filtered |
                                            Select-Object `
                                                State,
                                                LocalAddress,
                                                LocalPort,
                                                RemoteAddress,
                                                RemotePort,
                                                OwningProcess |
                                            Format-Table -AutoSize
                                    }
                                }
                                catch {

                                    Write-Host "Unable to filter TCP connections." `
                                        -ForegroundColor Red
                                }

                                Pause-Screen

                                continue
                            }

                            "R" {

                                continue
                            }

                            "Escape" {

                                break
                            }
                        }

                        if ($tcpKey.Key -eq "Escape") {
                            break
                        }
                    }

                    continue
                }

                # =========================================================
                # UDP
                # =========================================================

                if ($selectedProtocol -eq 1) {

                    while ($true) {

                        Clear-Screen

                        Show-Header "$script:AppName > NETWORK > NETSTAT > UDP"

                        Write-Host ""

                        Write-Host "UDP ENDPOINTS" -ForegroundColor White
                        Write-Host "-------------" -ForegroundColor DarkGray

                        Write-Host ""

                        try {

                            $endpoints = @(
                                Get-NetUDPEndpoint |
                                    Sort-Object LocalPort, LocalAddress
                            )

                            if ($endpoints.Count -eq 0) {

                                Write-Host "No UDP endpoints found." `
                                    -ForegroundColor Yellow
                            }
                            else {

                                $endpoints |
                                    Select-Object `
                                        LocalAddress,
                                        LocalPort,
                                        RemoteAddress,
                                        RemotePort,
                                        OwningProcess |
                                    Format-Table -AutoSize
                            }
                        }
                        catch {

                            Write-Host "Unable to read UDP endpoints." `
                                -ForegroundColor Red

                            Write-Host ""

                            netstat.exe -ano -p udp
                        }

                        Write-Host ""

                        Write-Host "[F] Filter by UDP port | [R] Refresh | [ESC] Back" `
                            -ForegroundColor DarkGray

                        try {

                            $udpKey = [Console]::ReadKey($true)
                        }
                        catch {

                            return
                        }

                        switch ($udpKey.Key) {

                            "F" {

                                Write-Host ""

                                $port = Read-TUIInteger `
                                    "UDP port to filter" `
                                    443 `
                                    1 `
                                    65535

                                if ($null -eq $port) {
                                    continue
                                }

                                Show-Header `
                                    "$script:AppName > NETWORK > NETSTAT > FILTER UDP $port"

                                Write-Host ""

                                Write-Host (
                                    "Showing UDP endpoints where LocalPort or RemotePort = {0}" -f $port
                                ) -ForegroundColor White

                                Write-Host ""

                                try {

                                    $filtered = @(
                                        Get-NetUDPEndpoint |
                                            Where-Object {
                                                $_.LocalPort -eq $port -or
                                                $_.RemotePort -eq $port
                                            } |
                                            Sort-Object `
                                                LocalAddress,
                                                LocalPort,
                                                RemoteAddress,
                                                RemotePort
                                    )

                                    if ($filtered.Count -eq 0) {

                                        Write-Host (
                                            "No UDP endpoints found for port {0}." -f $port
                                        ) -ForegroundColor Yellow
                                    }
                                    else {

                                        $filtered |
                                            Select-Object `
                                                LocalAddress,
                                                LocalPort,
                                                RemoteAddress,
                                                RemotePort,
                                                OwningProcess |
                                            Format-Table -AutoSize
                                    }
                                }
                                catch {

                                    Write-Host "Unable to filter UDP endpoints." `
                                        -ForegroundColor Red
                                }

                                Pause-Screen

                                continue
                            }

                            "R" {

                                continue
                            }

                            "Escape" {

                                break
                            }
                        }

                        if ($udpKey.Key -eq "Escape") {
                            break
                        }
                    }

                    continue
                }
            }
        }
    }
}

# =========================================================================
# DISK - USAGE
# =========================================================================

function Invoke-DiskUsage {

    Show-Header "$script:AppName > DISK > STORAGE"

    try {

        $disks = Get-CimInstance Win32_LogicalDisk `
            -Filter "DriveType=3"

        foreach ($disk in $disks) {

            $size = [Math]::Round(
                $disk.Size / 1GB,
                2
            )

            $free = [Math]::Round(
                $disk.FreeSpace / 1GB,
                2
            )

            if ($disk.Size -gt 0) {

                $usedPercent = [Math]::Round(
                    (
                        (
                            $disk.Size -
                            $disk.FreeSpace
                        ) /
                        $disk.Size
                    ) * 100,
                    1
                )
            }
            else {

                $usedPercent = 0
            }

            Write-Host ""

            Write-Host (
                "{0} - {1}" -f
                $disk.DeviceID,
                $disk.VolumeName
            ) -ForegroundColor White

            Write-Host "--------------------------------"

            Write-Host (
                "Size       : {0} GB" -f $size
            )

            Write-Host (
                "Free       : {0} GB" -f $free
            )

            if ($usedPercent -ge 90) {

                Write-Host (
                    "Used       : {0}%" -f $usedPercent
                ) -ForegroundColor Red
            }
            elseif ($usedPercent -ge 75) {

                Write-Host (
                    "Used       : {0}%" -f $usedPercent
                ) -ForegroundColor Yellow
            }
            else {

                Write-Host (
                    "Used       : {0}%" -f $usedPercent
                ) -ForegroundColor Green
            }
        }
    }
    catch {

        Write-Host "Unable to read disk information." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# DISK - VOLUMES
# =========================================================================

function Invoke-DiskVolumes {

    Show-Header "$script:AppName > DISK > VOLUMES"

    try {

        Get-Volume |
            Where-Object DriveLetter |
            Select-Object `
                DriveLetter,
                FileSystemLabel,
                FileSystem,
                HealthStatus,
                SizeRemaining,
                Size |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "Unable to read volume information." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# DISK - CHKDSK
# =========================================================================

function Invoke-CheckDisk {

    Show-Header "$script:AppName > DISK > CHECKDISK"

    if (-not (
        Require-Administrator "CHKDSK"
    )) {

        return
    }

    $drive = Read-TUIInput `
        "Drive letter [C:]: " `
        "C:"

    if ($null -eq $drive) {
        return
    }

    if ([string]::IsNullOrWhiteSpace($drive)) {
        return
    }

    $drive = $drive.Trim()

    if ($drive.Length -eq 1) {
        $drive += ":"
    }

    if ($drive -notmatch "^[A-Za-z]:$") {

        Write-Host ""

        Write-Host "Invalid drive letter." `
            -ForegroundColor Red

        Pause-Screen

        return
    }

    if (-not (
        Confirm-Action (
            "Run CHKDSK /SCAN on {0}?" -f $drive
        )
    )) {

        return
    }

    Write-Host ""

    chkdsk.exe $drive /scan

    Pause-Screen
}

# =========================================================================
# DISK - SFC
# =========================================================================

function Invoke-SFC {

    Show-Header "$script:AppName > DISK > SFC SCANNOW"

    if (-not (
        Require-Administrator "SFC /SCANNOW"
    )) {

        return
    }

    if (-not (
        Confirm-Action `
            "Run System File Checker /SCANNOW?"
    )) {

        return
    }

    Write-Host ""

    sfc.exe /scannow

    Pause-Screen
}

# =========================================================================
# DISM
# =========================================================================

function Invoke-DISMHealth {

    Show-Header "$script:AppName > DISK > DISM CHECK HEALTH"

    if (-not (
        Require-Administrator "DISM CheckHealth"
    )) {

        return
    }

    Write-Host ""

    DISM.exe `
        /Online `
        /Cleanup-Image `
        /CheckHealth

    Pause-Screen
}

function Invoke-DISMScan {

    Show-Header "$script:AppName > DISK > DISM SCAN HEALTH"

    if (-not (
        Require-Administrator "DISM ScanHealth"
    )) {

        return
    }

    Write-Host ""

    DISM.exe `
        /Online `
        /Cleanup-Image `
        /ScanHealth

    Pause-Screen
}

function Invoke-DISMRestore {

    Show-Header "$script:AppName > DISK > DISM RESTORE HEALTH"

    if (-not (
        Require-Administrator "DISM RestoreHealth"
    )) {

        return
    }

    if (-not (
        Confirm-Action `
            "Run DISM /RestoreHealth?"
    )) {

        return
    }

    Write-Host ""

    DISM.exe `
        /Online `
        /Cleanup-Image `
        /RestoreHealth

    Pause-Screen
}

# =========================================================================
# WINDOWS VERSION
# =========================================================================

function Invoke-WindowsVersion {

    Show-Header "$script:AppName > WINDOWS > VERSION"

    try {

        $os = Get-CimInstance Win32_OperatingSystem

        Write-Host (
            "Caption        : {0}" -f $os.Caption
        )

        Write-Host (
            "Version        : {0}" -f $os.Version
        )

        Write-Host (
            "Build          : {0}" -f $os.BuildNumber
        )

        Write-Host (
            "Architecture   : {0}" -f $os.OSArchitecture
        )

        Write-Host (
            "Install Date   : {0}" -f $os.InstallDate
        )

        Write-Host (
            "Last Boot      : {0}" -f $os.LastBootUpTime
        )
    }
    catch {

        Write-Host "Unable to read Windows version." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# PATCHES
# =========================================================================

function Invoke-HotFixes {

    Show-Header "$script:AppName > WINDOWS > INSTALLED PATCHES"

    try {

        Get-HotFix |
            Sort-Object InstalledOn -Descending |
            Select-Object -First 50 `
                HotFixID,
                Description,
                InstalledOn,
                InstalledBy |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "Unable to retrieve installed patches." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# GPUPDATE
# =========================================================================

function Invoke-GPUpdate {

    Show-Header "$script:AppName > WINDOWS > GPUPDATE"

    Write-Host ""

    gpupdate.exe /force

    Pause-Screen
}

# =========================================================================
# WINDOWS UPDATE SCAN
# =========================================================================

function Invoke-WindowsUpdateScan {

    Show-Header "$script:AppName > WINDOWS > UPDATE SCAN"

    if (-not (
        Require-Administrator "Windows Update scan"
    )) {

        return
    }

    Write-Host ""

    try {

        $uso = "$env:SystemRoot\System32\UsoClient.exe"

        if (Test-Path $uso) {

            Start-Process `
                -FilePath $uso `
                -ArgumentList "StartScan" `
                -WindowStyle Hidden

            Write-Host (
                "Windows Update scan requested."
            ) -ForegroundColor Green
        }
        else {

            Write-Host (
                "UsoClient.exe was not found."
            ) -ForegroundColor Yellow
        }
    }
    catch {

        Write-Host (
            "Unable to start Windows Update scan."
        ) -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# WINDOWS UPDATE SETTINGS
# =========================================================================

function Invoke-WindowsUpdatePage {

    Show-Header "$script:AppName > WINDOWS > WINDOWS UPDATE"

    try {

        Start-Process `
            "ms-settings:windowsupdate"

        Write-Host (
            "Windows Update settings opened."
        ) -ForegroundColor Green
    }
    catch {

        Write-Host (
            "Unable to open Windows Update."
        ) -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# COMPONENT CLEANUP
# =========================================================================

function Invoke-ComponentCleanup {

    Show-Header "$script:AppName > WINDOWS > COMPONENT CLEANUP"

    if (-not (
        Require-Administrator "DISM component cleanup"
    )) {

        return
    }

    if (-not (
        Confirm-Action `
            "Run DISM component cleanup?"
    )) {

        return
    }

    Write-Host ""

    DISM.exe `
        /Online `
        /Cleanup-Image `
        /StartComponentCleanup

    Pause-Screen
}

# =========================================================================
# SYSTEM INFORMATION
# =========================================================================

function Invoke-ComputerInfo {

    Show-Header "$script:AppName > SYSTEM > COMPUTER INFORMATION"

    try {

        $computer = Get-CimInstance Win32_ComputerSystem
        $bios = Get-CimInstance Win32_BIOS
        $os = Get-CimInstance Win32_OperatingSystem

        Write-Host "COMPUTER" -ForegroundColor White
        Write-Host "--------" -ForegroundColor DarkGray

        Write-Host (
            "Hostname       : {0}" -f
            $env:COMPUTERNAME
        )

        Write-Host (
            "Manufacturer   : {0}" -f
            $computer.Manufacturer
        )

        Write-Host (
            "Model          : {0}" -f
            $computer.Model
        )

        Write-Host (
            "Domain         : {0}" -f
            $computer.Domain
        )

        $ram = [Math]::Round(
            $computer.TotalPhysicalMemory / 1GB,
            2
        )

        Write-Host (
            "Total RAM      : {0} GB" -f
            $ram
        )

        Write-Host ""

        Write-Host "BIOS" -ForegroundColor White
        Write-Host "---" -ForegroundColor DarkGray

        Write-Host (
            "Manufacturer   : {0}" -f
            $bios.Manufacturer
        )

        Write-Host (
            "Version        : {0}" -f
            $bios.SMBIOSBIOSVersion
        )

        Write-Host (
            "Serial         : {0}" -f
            $bios.SerialNumber
        )

        Write-Host ""

        Write-Host "WINDOWS" -ForegroundColor White
        Write-Host "-------" -ForegroundColor DarkGray

        Write-Host (
            "Caption        : {0}" -f
            $os.Caption
        )

        Write-Host (
            "Build          : {0}" -f
            $os.BuildNumber
        )

        Write-Host (
            "Architecture   : {0}" -f
            $os.OSArchitecture
        )
    }
    catch {

        Write-Host "Unable to retrieve computer information." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# PROCESSES
# =========================================================================

function Invoke-Processes {

    Show-Header "$script:AppName > SYSTEM > PROCESSES"

    try {

        Get-Process |
            Sort-Object CPU -Descending |
            Select-Object -First 40 `
                Id,
                ProcessName,
                CPU,
                WorkingSet |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "Unable to retrieve processes." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# SERVICES
# =========================================================================

function Invoke-Services {

    Show-Header "$script:AppName > SYSTEM > SERVICES"

    try {

        Get-Service |
            Sort-Object Status, DisplayName |
            Select-Object -First 100 `
                Status,
                Name,
                DisplayName |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "Unable to retrieve services." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# ENVIRONMENT
# =========================================================================

function Invoke-SystemEnvironment {

    Show-Header "$script:AppName > SYSTEM > ENVIRONMENT"

    Get-ChildItem Env: |
        Sort-Object Name |
        Format-Table Name, Value -AutoSize

    Pause-Screen
}

# =========================================================================
# EVENT LOG
# =========================================================================

function Invoke-EventLogErrors {

    Show-Header "$script:AppName > SYSTEM > RECENT ERRORS"

    try {

        Get-WinEvent `
            -FilterHashtable @{
                LogName = "System"
                Level = 2
            } `
            -MaxEvents 30 |
            Select-Object `
                TimeCreated,
                Id,
                ProviderName,
                LevelDisplayName,
                Message |
            Format-List
    }
    catch {

        Write-Host "Unable to read event log." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# CURRENT USER
# =========================================================================

function Invoke-CurrentUser {

    Show-Header "$script:AppName > USER > CURRENT USER"

    try {

        $user = [Security.Principal.WindowsIdentity]::GetCurrent()

        Write-Host (
            "Name           : {0}" -f
            $user.Name
        )

        Write-Host (
            "Authentication : {0}" -f
            $user.AuthenticationType
        )

        Write-Host ""

        whoami.exe /all
    }
    catch {

        Write-Host "Unable to retrieve user information." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# LOCAL USERS
# =========================================================================

function Invoke-LocalUsers {

    Show-Header "$script:AppName > USER > LOCAL USERS"

    try {

        Get-LocalUser |
            Select-Object `
                Name,
                Enabled,
                Description,
                LastLogon,
                PasswordRequired |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "Unable to enumerate local users." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# RENAME USER
# =========================================================================

function Invoke-RenameLocalUser {

    Show-Header "$script:AppName > USER > RENAME LOCAL USER"

    if (-not (
        Require-Administrator "Rename local user"
    )) {

        return
    }

    $oldName = Read-TUIInput "Current username: "

    if ($null -eq $oldName) {
        return
    }

    if ([string]::IsNullOrWhiteSpace($oldName)) {
        return
    }

    try {

        $user = Get-LocalUser `
            -Name $oldName
    }
    catch {

        $user = $null
    }

    if (-not $user) {

        Write-Host ""

        Write-Host (
            "User '{0}' was not found." -f $oldName
        ) -ForegroundColor Red

        Pause-Screen

        return
    }

    $newName = Read-TUIInput "New username: "

    if ($null -eq $newName) {
        return
    }

    if ([string]::IsNullOrWhiteSpace($newName)) {
        return
    }

    if ($newName -notmatch "^[a-zA-Z0-9._-]+$") {

        Write-Host ""

        Write-Host "Invalid username." `
            -ForegroundColor Red

        Pause-Screen

        return
    }

    if (-not (
        Confirm-Action (
            "Rename '{0}' to '{1}'?" -f
            $oldName,
            $newName
        )
    )) {

        return
    }

    try {

        Rename-LocalUser `
            -Name $oldName `
            -NewName $newName

        Write-Host ""

        Write-Host (
            "User renamed successfully."
        ) -ForegroundColor Green
    }
    catch {

        Write-Host ""

        Write-Host (
            "Failed to rename user."
        ) -ForegroundColor Red

        Write-Host (
            $_.Exception.Message
        ) -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# LOCAL GROUPS
# =========================================================================

function Invoke-UserGroups {

    Show-Header "$script:AppName > USER > LOCAL GROUPS"

    try {

        Get-LocalGroup |
            Select-Object `
                Name,
                Description |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "Unable to enumerate local groups." `
            -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# FLUSH DNS
# =========================================================================

function Invoke-FlushDNS {

    Show-Header "$script:AppName > REPAIR > FLUSH DNS"

    if (-not (
        Require-Administrator "Flush DNS"
    )) {

        return
    }

    Write-Host ""

    ipconfig.exe /flushdns

    Pause-Screen
}

# =========================================================================
# DHCP RENEW
# =========================================================================

function Invoke-DHCPRenew {

    Show-Header "$script:AppName > REPAIR > DHCP RENEW"

    if (-not (
        Require-Administrator "DHCP renew"
    )) {

        return
    }

    if (-not (
        Confirm-Action `
            "The network connection may temporarily disconnect."
    )) {

        return
    }

    Write-Host ""

    ipconfig.exe /renew

    Pause-Screen
}

# =========================================================================
# WINSOCK RESET
# =========================================================================

function Invoke-WinsockReset {

    Show-Header "$script:AppName > REPAIR > WINSOCK RESET"

    if (-not (
        Require-Administrator "Winsock reset"
    )) {

        return
    }

    if (-not (
        Confirm-Action `
            "Winsock reset may require a restart."
    )) {

        return
    }

    Write-Host ""

    netsh.exe winsock reset

    Write-Host ""

    Write-Host (
        "A restart may be required."
    ) -ForegroundColor Yellow

    Pause-Screen
}

# =========================================================================
# TCP/IP RESET
# =========================================================================

function Invoke-TCPIPReset {

    Show-Header "$script:AppName > REPAIR > TCP/IP RESET"

    if (-not (
        Require-Administrator "TCP/IP reset"
    )) {

        return
    }

    if (-not (
        Confirm-Action `
            "TCP/IP reset may require a restart."
    )) {

        return
    }

    Write-Host ""

    netsh.exe int ip reset

    Write-Host ""

    Write-Host (
        "A restart may be required."
    ) -ForegroundColor Yellow

    Pause-Screen
}

# =========================================================================
# NETWORK RESET INFO
# =========================================================================

function Invoke-NetworkReset {

    Show-Header "$script:AppName > REPAIR > NETWORK RESET INFO"

    Write-Host "RECOMMENDED NETWORK REPAIR ORDER" `
        -ForegroundColor White

    Write-Host "--------------------------------"

    Write-Host ""

    Write-Host "1. Flush DNS"
    Write-Host "2. Renew DHCP"
    Write-Host "3. Reset Winsock"
    Write-Host "4. Reset TCP/IP"

    Write-Host ""

    Write-Host (
        "The toolbox does not automatically perform a complete"
    ) -ForegroundColor Yellow

    Write-Host (
        "Windows network reset because it can remove adapter"
    ) -ForegroundColor Yellow

    Write-Host (
        "configuration."
    ) -ForegroundColor Yellow

    Pause-Screen
}

# =========================================================================
# NETWORK REPORT
# =========================================================================

function Invoke-NetworkReport {

    Show-Header "$script:AppName > DIAGNOSTICS > NETWORK REPORT"

    $desktop = [Environment]::GetFolderPath("Desktop")

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    $path = Join-Path `
        $desktop `
        "NetworkReport_$timestamp.txt"

    Write-Host (
        "Generating network report..."
    ) -ForegroundColor White

    try {

        $output = New-Object `
            System.Collections.Generic.List[string]

        $output.Add(
            "WINDOWS ADMIN TOOLBOX - NETWORK REPORT"
        )

        $output.Add(
            "========================================"
        )

        $output.Add("")

        $output.Add(
            "Date: $(Get-Date)"
        )

        $output.Add(
            "Hostname: $env:COMPUTERNAME"
        )

        $output.Add(
            "User: $env:USERNAME"
        )

        $output.Add("")

        $output.Add("IPCONFIG /ALL")
        $output.Add("-------------")

        foreach ($line in @(ipconfig.exe /all)) {

            $output.Add([string]$line)
        }

        $output.Add("")

        $output.Add("NETWORK ADAPTERS")
        $output.Add("----------------")

        $adapterText = Get-NetAdapter |
            Format-Table -AutoSize |
            Out-String

        foreach (
            $line in (
                $adapterText -split "`r?`n"
            )
        ) {

            $output.Add($line)
        }

        $output.Add("")

        $output.Add("IP ADDRESSES")
        $output.Add("------------")

        $ipText = Get-NetIPAddress |
            Format-Table -AutoSize |
            Out-String

        foreach (
            $line in (
                $ipText -split "`r?`n"
            )
        ) {

            $output.Add($line)
        }

        $output.Add("")

        $output.Add("ROUTING TABLE")
        $output.Add("-------------")

        $routeText = Get-NetRoute |
            Format-Table -AutoSize |
            Out-String

        foreach (
            $line in (
                $routeText -split "`r?`n"
            )
        ) {

            $output.Add($line)
        }

        $output.Add("")

        $output.Add("FIREWALL")
        $output.Add("--------")

        $firewallText = Get-NetFirewallProfile |
            Format-Table -AutoSize |
            Out-String

        foreach (
            $line in (
                $firewallText -split "`r?`n"
            )
        ) {

            $output.Add($line)
        }

        $output.Add("")

        $output.Add("NETSTAT")
        $output.Add("-------")

        foreach ($line in @(netstat.exe -ano)) {

            $output.Add([string]$line)
        }

        $output |
            Set-Content `
                -Path $path `
                -Encoding UTF8

        Write-Host ""

        Write-Host "REPORT CREATED" `
            -ForegroundColor Green

        Write-Host ""

        Write-Host $path `
            -ForegroundColor White
    }
    catch {

        Write-Host ""

        Write-Host (
            "Failed to create report."
        ) -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# SYSTEM REPORT
# =========================================================================

function Invoke-SystemReport {

    Show-Header "$script:AppName > DIAGNOSTICS > SYSTEM REPORT"

    $desktop = [Environment]::GetFolderPath("Desktop")

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    $path = Join-Path `
        $desktop `
        "SystemReport_$timestamp.txt"

    Write-Host (
        "Generating system report..."
    ) -ForegroundColor White

    try {

        systeminfo.exe |
            Out-File `
                -FilePath $path `
                -Encoding UTF8

        Write-Host ""

        Write-Host "REPORT CREATED" `
            -ForegroundColor Green

        Write-Host ""

        Write-Host $path `
            -ForegroundColor White
    }
    catch {

        Write-Host ""

        Write-Host (
            "Failed to create report."
        ) -ForegroundColor Red
    }

    Pause-Screen
}

# =========================================================================
# ACTION DISPATCHER
# =========================================================================

function Invoke-Action {

    param(
        [string]$Action
    )

    switch ($Action) {

        "Dashboard" {
            Show-Dashboard
        }

        "Ping" {
            Invoke-Ping
        }

        "Tracert" {
            Invoke-Tracert
        }

        "DNSLookup" {
            Invoke-DNSLookup
        }

        "ReverseDNS" {
            Invoke-ReverseDNS
        }

        "PortCheck" {
            Invoke-PortCheck
        }

        "Adapters" {
            Invoke-Adapters
        }

        "IPAddresses" {
            Invoke-IPAddresses
        }

        "Routes" {
            Invoke-Routes
        }

        "ARP" {
            Invoke-ARP
        }

        "Netstat" {
            Invoke-Netstat
        }

        "DiskUsage" {
            Invoke-DiskUsage
        }

        "DiskVolumes" {
            Invoke-DiskVolumes
        }

        "CheckDisk" {
            Invoke-CheckDisk
        }

        "SFC" {
            Invoke-SFC
        }

        "DISMHealth" {
            Invoke-DISMHealth
        }

        "DISMScan" {
            Invoke-DISMScan
        }

        "DISMRestore" {
            Invoke-DISMRestore
        }

        "WindowsVersion" {
            Invoke-WindowsVersion
        }

        "HotFixes" {
            Invoke-HotFixes
        }

        "GPUpdate" {
            Invoke-GPUpdate
        }

        "WindowsUpdateScan" {
            Invoke-WindowsUpdateScan
        }

        "WindowsUpdatePage" {
            Invoke-WindowsUpdatePage
        }

        "ComponentCleanup" {
            Invoke-ComponentCleanup
        }

        "ComputerInfo" {
            Invoke-ComputerInfo
        }

        "Processes" {
            Invoke-Processes
        }

        "Services" {
            Invoke-Services
        }

        "Environment" {
            Invoke-SystemEnvironment
        }

        "SystemErrors" {
            Invoke-EventLogErrors
        }

        "CurrentUser" {
            Invoke-CurrentUser
        }

        "LocalUsers" {
            Invoke-LocalUsers
        }

        "RenameUser" {
            Invoke-RenameLocalUser
        }

        "UserGroups" {
            Invoke-UserGroups
        }

        "FlushDNS" {
            Invoke-FlushDNS
        }

        "DHCPRenew" {
            Invoke-DHCPRenew
        }

        "WinsockReset" {
            Invoke-WinsockReset
        }

        "TCPIPReset" {
            Invoke-TCPIPReset
        }

        "NetworkReset" {
            Invoke-NetworkReset
        }

        "NetworkReport" {
            Invoke-NetworkReport
        }

        "SystemReport" {
            Invoke-SystemReport
        }
    }
}

# =========================================================================
# MENU DEFINITIONS
# =========================================================================

$script:MainMenu = @(

    @{
        Name = "DASHBOARD"
        Description = "Hostname, Windows, IP, gateway and firewall"
        Type = "action"
        Target = "Dashboard"
    }

    @{
        Name = "NETWORK"
        Description = "Ping, DNS, ports, adapters, routes and connections"
        Type = "submenu"
        Target = "Network"
    }

    @{
        Name = "DISK & STORAGE"
        Description = "Disk usage, CHKDSK, SFC and DISM"
        Type = "submenu"
        Target = "Disk"
    }

    @{
        Name = "WINDOWS & UPDATES"
        Description = "Version, patches, Group Policy and updates"
        Type = "submenu"
        Target = "Windows"
    }

    @{
        Name = "SYSTEM"
        Description = "Computer information, processes and services"
        Type = "submenu"
        Target = "System"
    }

    @{
        Name = "USER & ACCOUNT"
        Description = "Users, groups and local account management"
        Type = "submenu"
        Target = "User"
    }

    @{
        Name = "REPAIR & MAINTENANCE"
        Description = "DNS, DHCP, Winsock and TCP/IP repair"
        Type = "submenu"
        Target = "Repair"
    }

    @{
        Name = "DIAGNOSTICS"
        Description = "Network and system reports"
        Type = "submenu"
        Target = "Diagnostics"
    }

    @{
        Name = "EXIT"
        Description = "Close the toolbox"
        Type = "exit"
        Target = ""
    }
)

$script:Menus = @{}

# =========================================================================
# NETWORK MENU
# =========================================================================

$script:Menus["Network"] = @(

    @{
        Name = "PING"
        Description = "Test connectivity and packet loss"
        Type = "action"
        Target = "Ping"
    }

    @{
        Name = "TRACEROUTE"
        Description = "Trace the route to a destination"
        Type = "action"
        Target = "Tracert"
    }

    @{
        Name = "DNS LOOKUP"
        Description = "Resolve a hostname"
        Type = "action"
        Target = "DNSLookup"
    }

    @{
        Name = "REVERSE DNS"
        Description = "Resolve an IP address"
        Type = "action"
        Target = "ReverseDNS"
    }

    @{
        Name = "TCP PORT CHECK"
        Description = "Check whether a TCP port is reachable"
        Type = "action"
        Target = "PortCheck"
    }

    @{
        Name = "NETWORK ADAPTERS"
        Description = "Show Ethernet and Wi-Fi adapters"
        Type = "action"
        Target = "Adapters"
    }

    @{
        Name = "IP ADDRESSES"
        Description = "Show IPv4 and IPv6 addresses"
        Type = "action"
        Target = "IPAddresses"
    }

    @{
        Name = "ROUTING TABLE"
        Description = "Show Windows routing table"
        Type = "action"
        Target = "Routes"
    }

    @{
        Name = "ARP / NEIGHBORS"
        Description = "Show local network neighbors"
        Type = "action"
        Target = "ARP"
    }

    @{
        Name = "NETSTAT"
        Description = "Show active network connections"
        Type = "action"
        Target = "Netstat"
    }
)

# =========================================================================
# DISK MENU
# =========================================================================

$script:Menus["Disk"] = @(

    @{
        Name = "DISK USAGE"
        Description = "Show free and used space"
        Type = "action"
        Target = "DiskUsage"
    }

    @{
        Name = "DISK VOLUMES"
        Description = "Show volume health and filesystem information"
        Type = "action"
        Target = "DiskVolumes"
    }

    @{
        Name = "CHECK DISK"
        Description = "Run CHKDSK /SCAN"
        Type = "action"
        Target = "CheckDisk"
    }

    @{
        Name = "SFC SCANNOW"
        Description = "Scan protected Windows system files"
        Type = "action"
        Target = "SFC"
    }

    @{
        Name = "DISM CHECK HEALTH"
        Description = "Check Windows component health"
        Type = "action"
        Target = "DISMHealth"
    }

    @{
        Name = "DISM SCAN HEALTH"
        Description = "Deep component store scan"
        Type = "action"
        Target = "DISMScan"
    }

    @{
        Name = "DISM RESTORE HEALTH"
        Description = "Repair the Windows component store"
        Type = "action"
        Target = "DISMRestore"
    }
)

# =========================================================================
# WINDOWS MENU
# =========================================================================

$script:Menus["Windows"] = @(

    @{
        Name = "WINDOWS VERSION"
        Description = "Show Windows version and build"
        Type = "action"
        Target = "WindowsVersion"
    }

    @{
        Name = "INSTALLED PATCHES"
        Description = "Show installed Windows hotfixes"
        Type = "action"
        Target = "HotFixes"
    }

    @{
        Name = "GPUPDATE /FORCE"
        Description = "Refresh computer and user Group Policy"
        Type = "action"
        Target = "GPUpdate"
    }

    @{
        Name = "WINDOWS UPDATE SCAN"
        Description = "Request a Windows Update scan"
        Type = "action"
        Target = "WindowsUpdateScan"
    }

    @{
        Name = "WINDOWS UPDATE"
        Description = "Open Windows Update settings"
        Type = "action"
        Target = "WindowsUpdatePage"
    }

    @{
        Name = "COMPONENT CLEANUP"
        Description = "Clean superseded Windows components"
        Type = "action"
        Target = "ComponentCleanup"
    }
)

# =========================================================================
# SYSTEM MENU
# =========================================================================

$script:Menus["System"] = @(

    @{
        Name = "COMPUTER INFORMATION"
        Description = "Hostname, manufacturer, BIOS and RAM"
        Type = "action"
        Target = "ComputerInfo"
    }

    @{
        Name = "PROCESSES"
        Description = "Show running processes"
        Type = "action"
        Target = "Processes"
    }

    @{
        Name = "SERVICES"
        Description = "Show Windows services"
        Type = "action"
        Target = "Services"
    }

    @{
        Name = "ENVIRONMENT"
        Description = "Show Windows environment variables"
        Type = "action"
        Target = "Environment"
    }

    @{
        Name = "SYSTEM ERRORS"
        Description = "Show recent Windows system errors"
        Type = "action"
        Target = "SystemErrors"
    }
)

# =========================================================================
# USER MENU
# =========================================================================

$script:Menus["User"] = @(

    @{
        Name = "CURRENT USER"
        Description = "Show current Windows identity"
        Type = "action"
        Target = "CurrentUser"
    }

    @{
        Name = "LOCAL USERS"
        Description = "List local Windows accounts"
        Type = "action"
        Target = "LocalUsers"
    }

    @{
        Name = "RENAME LOCAL USER"
        Description = "Rename a local Windows account"
        Type = "action"
        Target = "RenameUser"
    }

    @{
        Name = "LOCAL GROUPS"
        Description = "List local Windows groups"
        Type = "action"
        Target = "UserGroups"
    }
)

# =========================================================================
# REPAIR MENU
# =========================================================================

$script:Menus["Repair"] = @(

    @{
        Name = "FLUSH DNS"
        Description = "Clear the DNS resolver cache"
        Type = "action"
        Target = "FlushDNS"
    }

    @{
        Name = "DHCP RENEW"
        Description = "Request a new DHCP lease"
        Type = "action"
        Target = "DHCPRenew"
    }

    @{
        Name = "WINSOCK RESET"
        Description = "Reset the Windows Winsock catalog"
        Type = "action"
        Target = "WinsockReset"
    }

    @{
        Name = "TCP/IP RESET"
        Description = "Reset the Windows TCP/IP stack"
        Type = "action"
        Target = "TCPIPReset"
    }

    @{
        Name = "COMPONENT CLEANUP"
        Description = "Clean superseded Windows components"
        Type = "action"
        Target = "ComponentCleanup"
    }

    @{
        Name = "NETWORK RESET INFO"
        Description = "Show safer network repair recommendations"
        Type = "action"
        Target = "NetworkReset"
    }
)

# =========================================================================
# DIAGNOSTICS MENU
# =========================================================================

$script:Menus["Diagnostics"] = @(

    @{
        Name = "NETWORK REPORT"
        Description = "Generate a detailed network report"
        Type = "action"
        Target = "NetworkReport"
    }

    @{
        Name = "SYSTEM REPORT"
        Description = "Generate a Windows system report"
        Type = "action"
        Target = "SystemReport"
    }
)

# =========================================================================
# MENU ENGINE
# =========================================================================

function Invoke-TUIMenu {

    param(
        [string]$MenuName,
        [string]$Title
    )

    if ($MenuName -eq "Main") {

        $items = $script:MainMenu
    }
    else {

        if (-not $script:Menus.ContainsKey($MenuName)) {

            return
        }

        $items = $script:Menus[$MenuName]
    }

    $selected = 0

    while ($true) {

        Clear-Screen

        Write-Host ""

        Write-Host $Title -ForegroundColor White

        Write-Host (
            "-" * $Title.Length
        ) -ForegroundColor DarkGray

        Write-Host ""

        Show-StatusBar

        Write-Host ""

        $terminalWidth = Get-TerminalWidth

        $lineWidth = $terminalWidth - 1

        foreach (
            $index in 0..($items.Count - 1)
        ) {

            $item = $items[$index]

            $name = [string]$item.Name

            $description = [string]$item.Description

            $nameWidth = 32

            $line = "  "

            $line += $name

            if ($name.Length -lt $nameWidth) {

                $line += (
                    " " * (
                        $nameWidth -
                        $name.Length
                    )
                )
            }
            else {

                $line += " "
            }

            $line += $description

            if ($line.Length -lt $lineWidth) {

                $line = $line.PadRight($lineWidth)
            }
            elseif ($line.Length -gt $lineWidth) {

                $line = $line.Substring(
                    0,
                    $lineWidth
                )
            }

            if ($index -eq $selected) {

                Write-Host `
                    $line `
                    -ForegroundColor Black `
                    -BackgroundColor White
            }
            else {

                Write-Host `
                    $line `
                    -ForegroundColor Gray `
                    -BackgroundColor Black
            }
        }

        Show-Footer

        try {

            $key = [Console]::ReadKey($true)
        }
        catch {

            return
        }

        switch ($key.Key) {

            "UpArrow" {

                $selected--

                if ($selected -lt 0) {

                    $selected =
                        $items.Count - 1
                }

                continue
            }

            "DownArrow" {

                $selected++

                if ($selected -ge $items.Count) {

                    $selected = 0
                }

                continue
            }

            "Escape" {

                return
            }

            "Q" {

                return
            }

            "R" {

                continue
            }

            "Enter" {

                $item = $items[$selected]

                if ($item.Type -eq "exit") {

                    return
                }

                if ($item.Type -eq "submenu") {

                    Invoke-TUIMenu `
                        -MenuName $item.Target `
                        -Title (
                            "$Title > $($item.Name)"
                        )

                    continue
                }

                if ($item.Type -eq "action") {

                    Invoke-Action `
                        -Action $item.Target

                    continue
                }
            }
        }
    }
}

# =========================================================================
# START APPLICATION
# =========================================================================

function Start-Toolbox {

    try {

        try {

            [Console]::Title = (
                "$script:AppName v$script:Version"
            )
        }
        catch {}

        Hide-Cursor

        Invoke-TUIMenu `
            -MenuName "Main" `
            -Title (
                "$script:AppName v$script:Version"
            )
    }
    finally {

        Show-Cursor

        Clear-Host

        Write-Host ""

        Write-Host (
            "$script:AppName closed."
        ) -ForegroundColor White

        Write-Host ""
    }
}

# =========================================================================
# RUN
# =========================================================================

Start-Toolbox
