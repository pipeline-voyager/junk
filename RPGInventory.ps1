#requires -Version 7.0
#AI AND REDDIT ASSISTED PROGRAM
<#
    RPG INVENTORY TUI
    Inspired by terminal UIs with Catppuccin/Nord aesthetics.

    Run:
        pwsh ./RPGInventory.ps1

    Controls:
        Arrow Keys / W A S D  = Navigate
        Enter                 = Select
        Esc                   = Back
        Q                     = Quit
        S                     = Save
        L                     = Load
        ?                     = Help
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================
# THEME
# ============================================================

$Themes = @{
    Catppuccin = @{
        Bg       = "`e[48;2;30;30;46m"
        Panel    = "`e[48;2;24;24;37m"
        Surface  = "`e[48;2;49;50;68m"
        Text     = "`e[38;2;205;214;244m"
        Muted    = "`e[38;2;147;153;178m"
        Blue     = "`e[38;2;137;180;250m"
        Lavender = "`e[38;2;203;166;247m"
        Pink     = "`e[38;2;245;194;231m"
        Green    = "`e[38;2;166;227;161m"
        Yellow   = "`e[38;2;249;226;175m"
        Peach    = "`e[38;2;250;179;135m"
        Red      = "`e[38;2;243;139;168m"
        Cyan     = "`e[38;2;148;226;213m"
    }

    Dark = @{
        Bg       = "`e[48;2;20;20;24m"
        Panel    = "`e[48;2;28;28;34m"
        Surface  = "`e[48;2;48;48;58m"
        Text     = "`e[38;2;230;230;235m"
        Muted    = "`e[38;2;145;145;155m"
        Blue     = "`e[38;2;120;170;255m"
        Lavender = "`e[38;2;180;150;255m"
        Pink     = "`e[38;2;255;130;190m"
        Green    = "`e[38;2;130;220;150m"
        Yellow   = "`e[38;2;240;210;100m"
        Peach    = "`e[38;2;255;170;120m"
        Red      = "`e[38;2;255;100;110m"
        Cyan     = "`e[38;2;100;220;220m"
    }

    Light = @{
        Bg       = "`e[48;2;239;241;245m"
        Panel    = "`e[48;2;230;232;238m"
        Surface  = "`e[48;2;205;208;218m"
        Text     = "`e[38;2;40;42;50m"
        Muted    = "`e[38;2;100;103;115m"
        Blue     = "`e[38;2;40;100;210m"
        Lavender = "`e[38;2;120;70;190m"
        Pink     = "`e[38;2;190;60;130m"
        Green    = "`e[38;2;40;145;70m"
        Yellow   = "`e[38;2;170;125;20m"
        Peach    = "`e[38;2;200;90;40m"
        Red      = "`e[38;2;200;50;70m"
        Cyan     = "`e[38;2;20;145;150m"
    }

    Nord = @{
        Bg       = "`e[48;2;46;52;64m"
        Panel    = "`e[48;2;59;66;82m"
        Surface  = "`e[48;2;67;76;94m"
        Text     = "`e[38;2;216;222;233m"
        Muted    = "`e[38;2;145;158;171m"
        Blue     = "`e[38;2;136;192;208m"
        Lavender = "`e[38;2;180;142;173m"
        Pink     = "`e[38;2;191;97;106m"
        Green    = "`e[38;2;163;190;140m"
        Yellow   = "`e[38;2;235;203;139m"
        Peach    = "`e[38;2;208;135;112m"
        Red      = "`e[38;2;191;97;106m"
        Cyan     = "`e[38;2;143;188;187m"
    }
}

$ThemeName = "Catppuccin"
$T = $Themes[$ThemeName]

$Reset = "`e[0m"
$Clear = "`e[2J`e[H"
$HideCursor = "`e[?25l"
$ShowCursor = "`e[?25h"

# ============================================================
# GAME DATA
# ============================================================

$Items = @(
    [pscustomobject]@{
        Id="iron-sword"; Name="Iron Sword"; Type="Weapon"; Slot="Weapon"
        Rarity="Common"; Damage=12; Defense=0; Value=35; Weight=3
        Description="A dependable sword forged for wandering adventurers."
    },
    [pscustomobject]@{
        Id="moonblade"; Name="Moonblade"; Type="Weapon"; Slot="Weapon"
        Rarity="Epic"; Damage=34; Defense=0; Value=480; Weight=2
        Description="A silver blade that hums under moonlight."
    },
    [pscustomobject]@{
        Id="wooden-bow"; Name="Wooden Bow"; Type="Weapon"; Slot="Weapon"
        Rarity="Common"; Damage=8; Defense=0; Value=25; Weight=2
        Description="Simple, light and surprisingly useful."
    },
    [pscustomobject]@{
        Id="leather-armor"; Name="Leather Armor"; Type="Armor"; Slot="Armor"
        Rarity="Common"; Damage=0; Defense=8; Value=40; Weight=5
        Description="Light armor favored by scouts and rogues."
    },
    [pscustomobject]@{
        Id="knight-plate"; Name="Knight Plate"; Type="Armor"; Slot="Armor"
        Rarity="Rare"; Damage=0; Defense=25; Value=350; Weight=12
        Description="Heavy steel armor bearing the mark of an old kingdom."
    },
    [pscustomobject]@{
        Id="iron-helm"; Name="Iron Helm"; Type="Armor"; Slot="Helmet"
        Rarity="Common"; Damage=0; Defense=5; Value=30; Weight=3
        Description="Keeps your skull attached to your body."
    },
    [pscustomobject]@{
        Id="crown-stars"; Name="Crown of Stars"; Type="Armor"; Slot="Helmet"
        Rarity="Legendary"; Damage=0; Defense=18; Value=900; Weight=1
        Description="A mysterious crown said to contain fragments of a dead constellation."
    },
    [pscustomobject]@{
        Id="wolf-ring"; Name="Wolf Ring"; Type="Accessory"; Slot="Ring"
        Rarity="Rare"; Damage=5; Defense=3; Value=220; Weight=0
        Description="A ring carved from the tooth of a giant wolf."
    },
    [pscustomobject]@{
        Id="amulet-dawn"; Name="Amulet of Dawn"; Type="Accessory"; Slot="Amulet"
        Rarity="Epic"; Damage=10; Defense=10; Value=500; Weight=1
        Description="Glows faintly whenever danger is close."
    },
    [pscustomobject]@{
        Id="health-potion"; Name="Health Potion"; Type="Consumable"; Slot=""
        Rarity="Common"; Damage=0; Defense=0; Value=15; Weight=1
        Description="Restores 30 HP."
    },
    [pscustomobject]@{
        Id="mana-potion"; Name="Mana Potion"; Type="Consumable"; Slot=""
        Rarity="Common"; Damage=0; Defense=0; Value=18; Weight=1
        Description="Restores 25 MP."
    },
    [pscustomobject]@{
        Id="elixir"; Name="Greater Elixir"; Type="Consumable"; Slot=""
        Rarity="Rare"; Damage=0; Defense=0; Value=90; Weight=1
        Description="Restores 75 HP and 50 MP."
    },
    [pscustomobject]@{
        Id="dragon-scale"; Name="Dragon Scale"; Type="Material"; Slot=""
        Rarity="Legendary"; Damage=0; Defense=0; Value=600; Weight=2
        Description="A nearly indestructible scale shed by an ancient dragon."
    },
    [pscustomobject]@{
        Id="wolf-pelt"; Name="Wolf Pelt"; Type="Material"; Slot=""
        Rarity="Common"; Damage=0; Defense=0; Value=12; Weight=2
        Description="Warm fur harvested from a forest wolf."
    },
    [pscustomobject]@{
        Id="crystal"; Name="Arcane Crystal"; Type="Material"; Slot=""
        Rarity="Rare"; Damage=0; Defense=0; Value=100; Weight=1
        Description="A magical crystal humming with unstable energy."
    },
    [pscustomobject]@{
        Id="ancient-key"; Name="Ancient Key"; Type="Quest"; Slot=""
        Rarity="Epic"; Damage=0; Defense=0; Value=0; Weight=1
        Description="Opens something very, very old."
    }
)

$Locations = @(
    "Whispering Woods",
    "Ashen Keep",
    "Moonlit Ruins",
    "Goblin Caves",
    "Dragon's Grave",
    "Forgotten Mine"
)

$Enemies = @(
    [pscustomobject]@{Name="Forest Wolf"; HP=35; XP=20; GoldMin=8; GoldMax=22; Loot=@("wolf-pelt","health-potion")}
    [pscustomobject]@{Name="Cave Goblin"; HP=55; XP=35; GoldMin=15; GoldMax=40; Loot=@("iron-sword","crystal")}
    [pscustomobject]@{Name="Ash Knight"; HP=110; XP=100; GoldMin=50; GoldMax=100; Loot=@("knight-plate","moonblade")}
    [pscustomobject]@{Name="Ancient Dragon"; HP=500; XP=1000; GoldMin=500; GoldMax=1000; Loot=@("dragon-scale","crown-stars","amulet-dawn")}
)

$Recipes = @(
    [pscustomobject]@{
        Name="Hunter's Tonic"
        Ingredients=@{"wolf-pelt"=2}
        Result="health-potion"
        Amount=2
    },
    [pscustomobject]@{
        Name="Arcane Elixir"
        Ingredients=@{"crystal"=2}
        Result="elixir"
        Amount=1
    },
    [pscustomobject]@{
        Name="Moonblade"
        Ingredients=@{"crystal"=3;"dragon-scale"=1}
        Result="moonblade"
        Amount=1
    }
)

# ============================================================
# PLAYER
# ============================================================

$Player = @{
    Name="Aria"
    Level=12
    XP=820
    XPNext=1200
    HP=92
    MaxHP=120
    MP=55
    MaxMP=80
    Gold=1240
    Strength=18
    Dexterity=14
    Intelligence=16
    Vitality=20
    Luck=11
    Capacity=80
    Location="Whispering Woods"

    Inventory=@{
        "iron-sword"=1
        "leather-armor"=1
        "iron-helm"=1
        "health-potion"=5
        "mana-potion"=3
        "wolf-pelt"=4
        "crystal"=2
    }

    Equipment=@{
        Weapon="iron-sword"
        Armor="leather-armor"
        Helmet="iron-helm"
        Ring=$null
        Amulet=$null
    }

    Stash=@{
        "wooden-bow"=1
        "dragon-scale"=1
        "ancient-key"=1
    }

    Quests=@(
        [pscustomobject]@{
            Name="A Hunter's First Hunt"
            Description="Defeat 3 forest creatures."
            Progress=2
            Goal=3
            Reward=150
            Done=$false
        },
        [pscustomobject]@{
            Name="Crystal Collector"
            Description="Collect 5 Arcane Crystals."
            Progress=2
            Goal=5
            Reward=300
            Done=$false
        },
        [pscustomobject]@{
            Name="The Old Key"
            Description="Find the entrance to the Moonlit Ruins."
            Progress=1
            Goal=1
            Reward=500
            Done=$true
        }
    )
}

$Log = New-Object System.Collections.Generic.List[string]
$Log.Add("Welcome back, $($Player.Name).")
$Log.Add("The world is waiting.")

# ============================================================
# UTILITY
# ============================================================

function Get-Item([string]$id) {
    return $Items | Where-Object Id -eq $id | Select-Object -First 1
}

function Add-Item([string]$id, [int]$amount=1) {
    if (-not $Player.Inventory.ContainsKey($id)) {
        $Player.Inventory[$id] = 0
    }

    $Player.Inventory[$id] += $amount
}

function Remove-Item([string]$id, [int]$amount=1) {
    if (-not $Player.Inventory.ContainsKey($id)) {
        return $false
    }

    if ($Player.Inventory[$id] -lt $amount) {
        return $false
    }

    $Player.Inventory[$id] -= $amount

    if ($Player.Inventory[$id] -le 0) {
        $Player.Inventory.Remove($id)
    }

    return $true
}

function Add-Stash([string]$id, [int]$amount=1) {
    if (-not $Player.Stash.ContainsKey($id)) {
        $Player.Stash[$id] = 0
    }

    $Player.Stash[$id] += $amount
}

function Get-InventoryWeight {
    $weight = 0

    foreach ($entry in $Player.Inventory.GetEnumerator()) {
        $item = Get-Item $entry.Key
        $weight += ($item.Weight * $entry.Value)
    }

    return $weight
}

function XP-Bar {
    $width = 22
    $ratio = [Math]::Min(1, $Player.XP / [double]$Player.XPNext)
    $filled = [Math]::Floor($width * $ratio)
    return ("█" * $filled) + ("░" * ($width - $filled))
}

function HP-Bar {
    $width = 18
    $ratio = [Math]::Max(0, [Math]::Min(1, $Player.HP / [double]$Player.MaxHP))
    $filled = [Math]::Floor($width * $ratio)
    return ("█" * $filled) + ("░" * ($width - $filled))
}

function Write-At($x, $y, $text, $color=$T.Text) {
    [Console]::SetCursorPosition($x,$y)
    Write-Host "$color$text$Reset" -NoNewline
}

function Draw-Line($x, $y, $width, $char="─", $color=$T.Muted) {
    Write-At $x $y (($char * $width).Substring(0,$width)) $color
}

function Truncate($text, $length) {
    if ($null -eq $text) { return "" }
    if ($text.Length -le $length) { return $text }
    return $text.Substring(0,$length-1) + "…"
}

function Clear-Screen {
    [Console]::Write($Clear)
}

function Pause-Game {
    Write-At 2 ([Console]::WindowHeight-2) "Press any key..." $T.Muted
    [Console]::ReadKey($true) | Out-Null
}

function Add-Log([string]$message) {
    $Log.Add($message)

    if ($Log.Count -gt 100) {
        $Log.RemoveAt(0)
    }
}

function Rarity-Color($rarity) {
    switch ($rarity) {
        "Common"    { return $T.Text }
        "Rare"      { return $T.Blue }
        "Epic"      { return $T.Lavender }
        "Legendary" { return $T.Yellow }
        default     { return $T.Text }
    }
}

# ============================================================
# HEADER
# ============================================================

function Draw-Header($title) {
    Write-At 2 0 "RPG // INVENTORY" $T.Lavender
    Write-At 24 0 "◆ $title" $T.Blue
    Write-At 54 0 "$($Player.Name)  LV.$($Player.Level)" $T.Text
    Write-At 74 0 "G $($Player.Gold)" $T.Yellow

    Draw-Line 2 1 96 "─" $T.Surface
}

# ============================================================
# LEFT SIDEBAR
# ============================================================

function Draw-Sidebar($selected) {
    $items = @(
        "Inventory",
        "Equipment",
        "Stash",
        "Character",
        "Crafting",
        "Hunt",
        "Quests",
        "World",
        "Merchant",
        "Event Log"
    )

    Write-At 2 3 "MENU" $T.Muted

    for ($i=0; $i -lt $items.Count; $i++) {
        $y = 5 + $i

        if ($i -eq $selected) {
            Write-At 2 $y "  $($items[$i])" $T.Bg
            [Console]::SetCursorPosition(2,$y)
            Write-Host "$($T.Lavender)$($T.Panel)$($items[$i].PadRight(18))$Reset" -NoNewline
        }
        else {
            Write-At 2 $y "  $($items[$i])" $T.Text
        }
    }

    Draw-Line 2 16 18
    Write-At 2 18 "SYSTEM" $T.Muted
    Write-At 2 20 "[S] Save" $T.Text
    Write-At 2 21 "[L] Load" $T.Text
    Write-At 2 22 "[T] Theme" $T.Text
    Write-At 2 23 "[?] Help" $T.Text
    Write-At 2 24 "[Q] Quit" $T.Red
}

# ============================================================
# PLAYER MINI PANEL
# ============================================================

function Draw-PlayerPanel {
    Write-At 68 3 "PLAYER" $T.Muted
    Write-At 68 5 "$($Player.Name)" $T.Pink
    Write-At 68 6 "Level $($Player.Level)" $T.Text

    Write-At 68 8 "HP" $T.Red
    Write-At 72 8 "$(HP-Bar) $($Player.HP)/$($Player.MaxHP)" $T.Text

    Write-At 68 10 "MP" $T.Cyan
    $mpWidth = 12
    $mpRatio = $Player.MP / [double]$Player.MaxMP
    $mpFill = [Math]::Floor($mpWidth * $mpRatio)
    $mpBar = ("█" * $mpFill) + ("░" * ($mpWidth-$mpFill))
    Write-At 72 10 "$mpBar $($Player.MP)/$($Player.MaxMP)" $T.Text

    Write-At 68 12 "XP" $T.Yellow
    Write-At 72 12 "$(XP-Bar)" $T.Yellow
}

# ============================================================
# INVENTORY
# ============================================================

function Inventory-Menu {
    $selected = 0
    $search = ""

    while ($true) {
        Clear-Screen
        Draw-Header "Inventory"
        Draw-Sidebar 0

        $all = @(
            foreach ($entry in $Player.Inventory.GetEnumerator()) {
                $item = Get-Item $entry.Key

                if (
                    [string]::IsNullOrWhiteSpace($search) -or
                    $item.Name -like "*$search*" -or
                    $item.Type -like "*$search*"
                ) {
                    [pscustomobject]@{
                        Item=$item
                        Count=$entry.Value
                    }
                }
            }
        )

        if ($all.Count -eq 0) {
            Write-At 23 5 "No items found." $T.Muted
        }
        else {
            $selected = [Math]::Min($selected, $all.Count-1)

            Write-At 23 3 "BACKPACK" $T.Muted
            Write-At 23 4 "Weight $(Get-InventoryWeight) / $($Player.Capacity)" $T.Text

            Draw-Line 23 6 42

            for ($i=0; $i -lt $all.Count; $i++) {
                $y = 8 + $i
                if ($y -ge 24) { break }

                $entry = $all[$i]
                $item = $entry.Item

                $prefix = if ($i -eq $selected) { "› " } else { "  " }
                $color = Rarity-Color $item.Rarity

                if ($i -eq $selected) {
                    Write-At 23 $y "$prefix$($item.Name.PadRight(25)) x$($entry.Count)" $T.Bg
                    [Console]::SetCursorPosition(23,$y)
                    Write-Host "$($T.Lavender)$($T.Surface)$prefix$($item.Name.PadRight(25)) x$($entry.Count)$Reset" -NoNewline
                }
                else {
                    Write-At 23 $y "$prefix$($item.Name.PadRight(25)) x$($entry.Count)" $color
                }
            }
        }

        Draw-ItemDetail -Entry $(if ($all.Count -gt 0) {$all[$selected]} else {$null})
        Draw-PlayerPanel

        Write-At 23 26 "[ENTER] Actions   [/] Search   [ESC] Back" $T.Muted

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            "UpArrow"   { $selected = [Math]::Max(0,$selected-1) }
            "DownArrow" { $selected = [Math]::Min([Math]::Max(0,$all.Count-1),$selected+1) }
            "Enter" {
                if ($all.Count -gt 0) {
                    Item-Actions $all[$selected].Item $all[$selected].Count
                }
            }
            "Escape" { return }
            "Q" { Exit-Game }
            "S" { Save-Game }
            "L" { Load-Game }
            "T" { Theme-Menu }
            "/" {
                $search = Read-Input "Search"
                $selected = 0
            }
        }
    }
}

function Draw-ItemDetail($Entry) {
    $x = 68

    Draw-Line $x 15 27
    Write-At $x 17 "ITEM DETAILS" $T.Muted

    if ($null -eq $Entry) {
        Write-At $x 19 "Nothing selected." $T.Muted
        return
    }

    $item = $Entry.Item

    Write-At $x 19 (Truncate $item.Name 27) (Rarity-Color $item.Rarity)
    Write-At $x 20 "$($item.Rarity) • $($item.Type)" $T.Muted

    if ($item.Damage -gt 0) {
        Write-At $x 22 "⚔ Damage  +$($item.Damage)" $T.Red
    }

    if ($item.Defense -gt 0) {
        Write-At $x 23 "◆ Defense +$($item.Defense)" $T.Blue
    }

    Write-At $x 25 "Value     $($item.Value)g" $T.Yellow
}

# ============================================================
# ITEM ACTIONS
# ============================================================

function Item-Actions($item, $count) {
    $selected = 0

    $actions = @("Use", "Equip", "Move to Stash", "Drop", "Cancel")

    while ($true) {
        Clear-Screen
        Draw-Header $item.Name

        Write-At 5 4 "$($item.Name)" (Rarity-Color $item.Rarity)
        Write-At 5 5 "$($item.Description)" $T.Muted
        Write-At 5 7 "Quantity: $count" $T.Text

        for ($i=0; $i -lt $actions.Count; $i++) {
            $y = 10 + $i

            if ($i -eq $selected) {
                Write-At 5 $y "› $($actions[$i])" $T.Lavender
            }
            else {
                Write-At 5 $y "  $($actions[$i])" $T.Text
            }
        }

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            "UpArrow"   { $selected = [Math]::Max(0,$selected-1) }
            "DownArrow" { $selected = [Math]::Min($actions.Count-1,$selected+1) }
            "Escape" { return }
            "Enter" {
                switch ($actions[$selected]) {
                    "Use" {
                        Use-Item $item
                        Pause-Game
                        return
                    }
                    "Equip" {
                        Equip-Item $item
                        Pause-Game
                        return
                    }
                    "Move to Stash" {
                        if (Remove-Item $item.Id) {
                            Add-Stash $item.Id
                            Add-Log "Moved $($item.Name) to stash."
                        }
                        Pause-Game
                        return
                    }
                    "Drop" {
                        if (Remove-Item $item.Id) {
                            Add-Log "Dropped $($item.Name)."
                        }
                        Pause-Game
                        return
                    }
                    "Cancel" { return }
                }
            }
        }
    }
}

function Use-Item($item) {
    if ($item.Type -ne "Consumable") {
        Add-Log "$($item.Name) cannot be consumed."
        return
    }

    if (-not (Remove-Item $item.Id)) {
        return
    }

    switch ($item.Id) {
        "health-potion" {
            $old = $Player.HP
            $Player.HP = [Math]::Min($Player.MaxHP,$Player.HP+30)
            Add-Log "Used Health Potion. HP $old → $($Player.HP)."
        }

        "mana-potion" {
            $old = $Player.MP
            $Player.MP = [Math]::Min($Player.MaxMP,$Player.MP+25)
            Add-Log "Used Mana Potion. MP $old → $($Player.MP)."
        }

        "elixir" {
            $Player.HP = [Math]::Min($Player.MaxHP,$Player.HP+75)
            $Player.MP = [Math]::Min($Player.MaxMP,$Player.MP+50)
            Add-Log "Used Greater Elixir. Your body glows."
        }
    }
}

function Equip-Item($item) {
    if ([string]::IsNullOrWhiteSpace($item.Slot)) {
        Add-Log "$($item.Name) cannot be equipped."
        return
    }

    $slot = $item.Slot
    $old = $Player.Equipment[$slot]

    if ($old) {
        Add-Item $old
        Add-Log "Unequipped $((Get-Item $old).Name)."
    }

    Remove-Item $item.Id | Out-Null
    $Player.Equipment[$slot] = $item.Id

    Add-Log "Equipped $($item.Name)."
}

# ============================================================
# EQUIPMENT
# ============================================================

function Equipment-Menu {
    $slots = @("Weapon","Armor","Helmet","Ring","Amulet")
    $selected = 0

    while ($true) {
        Clear-Screen
        Draw-Header "Equipment"
        Draw-Sidebar 1

        Write-At 24 3 "LOADOUT" $T.Muted

        # ASCII character
        Write-At 42 6 "       .-." $T.Lavender
        Write-At 42 7 "      (o o)" $T.Lavender
        Write-At 42 8 "      | O |" $T.Lavender
        Write-At 42 9 "      |   |" $T.Lavender
        Write-At 42 10 "     /|   |\" $T.Lavender
        Write-At 42 11 "    / |   | \" $T.Lavender
        Write-At 42 12 "      /   \" $T.Lavender
        Write-At 42 13 "     /     \" $T.Lavender

        for ($i=0; $i -lt $slots.Count; $i++) {
            $y = 5 + ($i*3)
            $slot = $slots[$i]
            $id = $Player.Equipment[$slot]

            $itemName = if ($id) {
                (Get-Item $id).Name
            } else {
                "[ Empty ]"
            }

            if ($i -eq $selected) {
                Write-At 24 $y "› $slot".PadRight(19) $T.Lavender
                Write-At 45 $y (Truncate $itemName 24) (if($id){Rarity-Color (Get-Item $id).Rarity}else{$T.Muted})
            }
            else {
                Write-At 24 $y "  $slot".PadRight(19) $T.Text
                Write-At 45 $y (Truncate $itemName 24) $T.Text
            }
        }

        Write-At 70 5 "COMBAT STATS" $T.Muted

        $damage = $Player.Strength
        $defense = $Player.Vitality

        foreach ($slot in $slots) {
            if ($Player.Equipment[$slot]) {
                $eq = Get-Item $Player.Equipment[$slot]
                $damage += $eq.Damage
                $defense += $eq.Defense
            }
        }

        Write-At 70 7 "Attack     $damage" $T.Red
        Write-At 70 8 "Defense    $defense" $T.Blue
        Write-At 70 9 "Strength   $($Player.Strength)" $T.Text
        Write-At 70 10 "Dexterity  $($Player.Dexterity)" $T.Text
        Write-At 70 11 "Intellect  $($Player.Intelligence)" $T.Text
        Write-At 70 12 "Vitality   $($Player.Vitality)" $T.Text
        Write-At 70 13 "Luck       $($Player.Luck)" $T.Text

        Write-At 24 24 "[ENTER] Unequip   [ESC] Back" $T.Muted

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            "UpArrow"   { $selected = [Math]::Max(0,$selected-1) }
            "DownArrow" { $selected = [Math]::Min($slots.Count-1,$selected+1) }
            "Enter" {
                $slot = $slots[$selected]
                $id = $Player.Equipment[$slot]

                if ($id) {
                    Add-Item $id
                    $Player.Equipment[$slot] = $null
                    Add-Log "Unequipped $((Get-Item $id).Name)."
                }
            }
            "Escape" { return }
            "Q" { Exit-Game }
        }
    }
}

# ============================================================
# STASH
# ============================================================

function Stash-Menu {
    $selected = 0
    $mode = "Stash"

    while ($true) {
        Clear-Screen
        Draw-Header "Stash"
        Draw-Sidebar 2

        Write-At 24 3 "STORAGE VAULT" $T.Muted
        Write-At 24 4 "Items here do not count toward backpack weight." $T.Text

        $all = @(
            foreach ($entry in $Player.Stash.GetEnumerator()) {
                [pscustomobject]@{
                    Item=(Get-Item $entry.Key)
                    Count=$entry.Value
                }
            }
        )

        if ($all.Count -gt 0) {
            $selected = [Math]::Min($selected,$all.Count-1)

            for ($i=0; $i -lt $all.Count; $i++) {
                $y = 7 + $i
                $item = $all[$i].Item

                if ($i -eq $selected) {
                    Write-At 24 $y "› $($item.Name.PadRight(30)) x$($all[$i].Count)" (Rarity-Color $item.Rarity)
                }
                else {
                    Write-At 24 $y "  $($item.Name.PadRight(30)) x$($all[$i].Count)" $T.Text
                }
            }
        }
        else {
            Write-At 24 7 "Stash is empty." $T.Muted
        }

        Write-At 24 24 "[ENTER] Take   [ESC] Back" $T.Muted

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            "UpArrow" { $selected=[Math]::Max(0,$selected-1) }
            "DownArrow" { $selected=[Math]::Min([Math]::Max(0,$all.Count-1),$selected+1) }
            "Enter" {
                if ($all.Count -gt 0) {
                    $item = $all[$selected].Item
                    $id = $item.Id

                    if (Remove-StashItem $id) {
                        Add-Item $id
                        Add-Log "Retrieved $($item.Name) from stash."
                    }
                }
            }
            "Escape" { return }
            "Q" { Exit-Game }
        }
    }
}

function Remove-StashItem($id) {
    if (-not $Player.Stash.ContainsKey($id)) {
        return $false
    }

    $Player.Stash[$id]--

    if ($Player.Stash[$id] -le 0) {
        $Player.Stash.Remove($id)
    }

    return $true
}

# ============================================================
# CHARACTER
# ============================================================

function Character-Menu {
    while ($true) {
        Clear-Screen
        Draw-Header "Character"
        Draw-Sidebar 3

        Write-At 24 3 "CHARACTER SHEET" $T.Muted

        Write-At 24 5 "$($Player.Name)" $T.Pink
        Write-At 24 6 "Level $($Player.Level)" $T.Text
        Write-At 24 8 "Experience" $T.Muted
        Write-At 24 9 "$($Player.XP) / $($Player.XPNext)" $T.Yellow

        Write-At 24 12 "ATTRIBUTES" $T.Muted

        $stats = @(
            @("Strength",$Player.Strength),
            @("Dexterity",$Player.Dexterity),
            @("Intelligence",$Player.Intelligence),
            @("Vitality",$Player.Vitality),
            @("Luck",$Player.Luck)
        )

        for ($i=0; $i -lt $stats.Count; $i++) {
            Write-At 24 (14+$i) "$($stats[$i][0].PadRight(15)) $($stats[$i][1])" $T.Text
        }

        Write-At 52 5 "SURVIVAL" $T.Muted
        Write-At 52 7 "HP          $($Player.HP) / $($Player.MaxHP)" $T.Red
        Write-At 52 8 "Mana        $($Player.MP) / $($Player.MaxMP)" $T.Cyan
        Write-At 52 10 "Carry       $(Get-InventoryWeight) / $($Player.Capacity)" $T.Text
        Write-At 52 11 "Gold        $($Player.Gold)g" $T.Yellow
        Write-At 52 13 "Location" $T.Muted
        Write-At 52 14 $Player.Location $T.Green

        Draw-Line 52 16 35

        Write-At 52 18 "COMBAT" $T.Muted

        $damage = $Player.Strength
        $defense = $Player.Vitality

        foreach ($eq in $Player.Equipment.Values) {
            if ($eq) {
                $obj = Get-Item $eq
                $damage += $obj.Damage
                $defense += $obj.Defense
            }
        }

        Write-At 52 20 "Attack      $damage" $T.Red
        Write-At 52 21 "Defense     $defense" $T.Blue

        Write-At 24 24 "[ESC] Back" $T.Muted

        $key=[Console]::ReadKey($true)

        if ($key.Key -eq "Escape") { return }
        if ($key.Key -eq "Q") { Exit-Game }
    }
}

# ============================================================
# CRAFTING
# ============================================================

function Crafting-Menu {
    $selected=0

    while ($true) {
        Clear-Screen
        Draw-Header "Crafting"
        Draw-Sidebar 4

        Write-At 24 3 "WORKBENCH" $T.Muted
        Write-At 24 4 "Combine materials into useful gear." $T.Text

        for ($i=0; $i -lt $Recipes.Count; $i++) {
            $recipe=$Recipes[$i]
            $y=7+($i*5)

            if ($i -eq $selected) {
                Write-At 24 $y "› $($recipe.Name)" $T.Lavender
            }
            else {
                Write-At 24 $y "  $($recipe.Name)" $T.Text
            }

            $ingredients = @()

            foreach ($ing in $recipe.Ingredients.GetEnumerator()) {
                $obj=Get-Item $ing.Key
                $have=if($Player.Inventory.ContainsKey($ing.Key)){$Player.Inventory[$ing.Key]}else{0}
                $ingredients += "$($obj.Name) $have/$($ing.Value)"
            }

            Write-At 28 ($y+1) ($ingredients -join "  ") $T.Muted
            Write-At 28 ($y+2) "→ $((Get-Item $recipe.Result).Name) x$($recipe.Amount)" $T.Green
        }

        Write-At 24 24 "[ENTER] Craft   [ESC] Back" $T.Muted

        $key=[Console]::ReadKey($true)

        switch ($key.Key) {
            "UpArrow" {$selected=[Math]::Max(0,$selected-1)}
            "DownArrow" {$selected=[Math]::Min($Recipes.Count-1,$selected+1)}
            "Escape" {return}
            "Enter" {
                $recipe=$Recipes[$selected]
                $canCraft=$true

                foreach ($ing in $recipe.Ingredients.GetEnumerator()) {
                    $have=if($Player.Inventory.ContainsKey($ing.Key)){$Player.Inventory[$ing.Key]}else{0}

                    if($have -lt $ing.Value) {
                        $canCraft=$false
                    }
                }

                if($canCraft) {
                    foreach ($ing in $recipe.Ingredients.GetEnumerator()) {
                        Remove-Item $ing.Key $ing.Value | Out-Null
                    }

                    Add-Item $recipe.Result $recipe.Amount
                    Add-Log "Crafted $($recipe.Name)."
                }
                else {
                    Add-Log "Not enough materials for $($recipe.Name)."
                }
            }
            "Q" {Exit-Game}
        }
    }
}

# ============================================================
# HUNT / COMBAT
# ============================================================

function Hunt-Menu {
    $selected=0

    while ($true) {
        Clear-Screen
        Draw-Header "Hunt"
        Draw-Sidebar 5

        Write-At 24 3 "ENCOUNTERS" $T.Muted
        Write-At 24 4 "Choose an enemy to hunt." $T.Text

        for($i=0;$i -lt $Enemies.Count;$i++) {
            $enemy=$Enemies[$i]
            $y=7+($i*3)

            if($i -eq $selected) {
                Write-At 24 $y "› $($enemy.Name)" $T.Red
            } else {
                Write-At 24 $y "  $($enemy.Name)" $T.Text
            }

            Write-At 50 $y "HP $($enemy.HP)  XP +$($enemy.XP)" $T.Muted
        }

        Write-At 24 24 "[ENTER] Hunt   [ESC] Back" $T.Muted

        $key=[Console]::ReadKey($true)

        switch($key.Key) {
            "UpArrow" {$selected=[Math]::Max(0,$selected-1)}
            "DownArrow" {$selected=[Math]::Min($Enemies.Count-1,$selected+1)}
            "Escape" {return}
            "Enter" {
                Combat $Enemies[$selected]
            }
            "Q" {Exit-Game}
        }
    }
}

function Combat($enemyTemplate) {
    $enemy=$enemyTemplate.PSObject.Copy()
    $enemyHP=$enemy.HP

    while($enemyHP -gt 0 -and $Player.HP -gt 0) {
        Clear-Screen
        Draw-Header "Combat // $($enemy.Name)"

        Write-At 25 5 "YOU" $T.Green
        Write-At 25 7 "HP $($Player.HP)/$($Player.MaxHP)" $T.Text
        Write-At 25 8 "$(HP-Bar)" $T.Green

        Write-At 60 5 $enemy.Name $T.Red
        Write-At 60 7 "HP $enemyHP/$($enemy.HP)" $T.Text

        $enemyBarWidth=18
        $enemyRatio=$enemyHP/[double]$enemy.HP
        $enemyFill=[Math]::Floor($enemyBarWidth*$enemyRatio)
        $enemyBar=("█"*$enemyFill)+("░"*($enemyBarWidth-$enemyFill))

        Write-At 60 8 $enemyBar $T.Red

        Write-At 25 12 "[A] Attack" $T.Red
        Write-At 25 13 "[P] Potion" $T.Green
        Write-At 25 14 "[R] Run" $T.Yellow

        $key=[Console]::ReadKey($true)

        if($key.Key -eq "A") {
            $weaponId=$Player.Equipment["Weapon"]
            $weapon=if($weaponId){Get-Item $weaponId}else{$null}

            $damage=$Player.Strength
            if($weapon) {
                $damage += $weapon.Damage
            }

            $damage=[Math]::Max(1,$damage+(Get-Random -Minimum -4 -Maximum 6))
            $enemyHP=[Math]::Max(0,$enemyHP-$damage)

            Add-Log "You hit $($enemy.Name) for $damage damage."

            if($enemyHP -gt 0) {
                $enemyDamage=[Math]::Max(1,(Get-Random -Minimum 4 -Maximum 13)-[Math]::Floor($Player.Vitality/8))
                $Player.HP=[Math]::Max(0,$Player.HP-$enemyDamage)
                Add-Log "$($enemy.Name) hits you for $enemyDamage."
            }
        }
        elseif($key.Key -eq "P") {
            if($Player.Inventory.ContainsKey("health-potion")) {
                Use-Item (Get-Item "health-potion")
            } else {
                Add-Log "You have no health potions."
            }
        }
        elseif($key.Key -eq "R") {
            Add-Log "You escaped from $($enemy.Name)."
            return
        }
        elseif($key.Key -eq "Q") {
            Exit-Game
        }
    }

    if($Player.HP -le 0) {
        $Player.HP=[Math]::Floor($Player.MaxHP*0.5)
        $Player.Gold=[Math]::Floor($Player.Gold*0.8)
        Add-Log "You were defeated and lost some gold."
        Pause-Game
        return
    }

    $gold=Get-Random -Minimum $enemy.GoldMin -Maximum ($enemy.GoldMax+1)

    $Player.Gold += $gold
    $Player.XP += $enemy.XP

    Add-Log "Defeated $($enemy.Name)! +$gold gold, +$($enemy.XP) XP."

    $loot=$enemy.Loot | Get-Random

    if($loot) {
        Add-Item $loot
        Add-Log "Looted $((Get-Item $loot).Name)."
    }

    while($Player.XP -ge $Player.XPNext) {
        $Player.XP -= $Player.XPNext
        $Player.Level++
        $Player.XPNext=[Math]::Floor($Player.XPNext*1.35)
        $Player.MaxHP+=10
        $Player.MaxMP+=5
        $Player.HP=$Player.MaxHP
        $Player.MP=$Player.MaxMP
        $Player.Strength++
        $Player.Vitality++

        Add-Log "LEVEL UP! You are now level $($Player.Level)."
    }

    Pause-Game
}

# ============================================================
# QUESTS
# ============================================================

function Quest-Menu {
    while($true) {
        Clear-Screen
        Draw-Header "Quests"
        Draw-Sidebar 6

        Write-At 24 3 "QUEST LOG" $T.Muted

        for($i=0;$i -lt $Player.Quests.Count;$i++) {
            $quest=$Player.Quests[$i]
            $y=6+($i*5)

            $color=if($quest.Done){$T.Green}else{$T.Text}
            $mark=if($quest.Done){"✓"}else{"◆"}

            Write-At 24 $y "$mark  $($quest.Name)" $color
            Write-At 28 ($y+1) (Truncate $quest.Description 52) $T.Muted
            Write-At 28 ($y+2) "Progress $($quest.Progress)/$($quest.Goal)" $T.Text
            Write-At 28 ($y+3) "Reward $($quest.Reward)g" $T.Yellow
        }

        Write-At 24 24 "[ESC] Back" $T.Muted

        $key=[Console]::ReadKey($true)

        if($key.Key -eq "Escape"){return}
        if($key.Key -eq "Q"){Exit-Game}
    }
}

# ============================================================
# WORLD
# ============================================================

function World-Menu {
    $selected=0

    while($true) {
        Clear-Screen
        Draw-Header "World"
        Draw-Sidebar 7

        Write-At 24 3 "WORLD MAP" $T.Muted

        for($i=0;$i -lt $Locations.Count;$i++) {
            $y=6+($i*3)

            if($Locations[$i] -eq $Player.Location) {
                Write-At 24 $y "◆ $($Locations[$i])" $T.Green
                Write-At 50 $y "CURRENT" $T.Green
            }
            elseif($i -eq $selected) {
                Write-At 24 $y "› $($Locations[$i])" $T.Lavender
            }
            else {
                Write-At 24 $y "  $($Locations[$i])" $T.Text
            }
        }

        Write-At 24 24 "[ENTER] Travel   [ESC] Back" $T.Muted

        $key=[Console]::ReadKey($true)

        switch($key.Key) {
            "UpArrow" {$selected=[Math]::Max(0,$selected-1)}
            "DownArrow" {$selected=[Math]::Min($Locations.Count-1,$selected+1)}
            "Enter" {
                $Player.Location=$Locations[$selected]
                Add-Log "Travelled to $($Player.Location)."
            }
            "Escape" {return}
            "Q" {Exit-Game}
        }
    }
}

# ============================================================
# MERCHANT
# ============================================================

function Merchant-Menu {
    $stock=@(
        "health-potion",
        "mana-potion",
        "wooden-bow",
        "leather-armor",
        "wolf-ring",
        "amulet-dawn"
    )

    $selected=0

    while($true) {
        Clear-Screen
        Draw-Header "Merchant"
        Draw-Sidebar 8

        Write-At 24 3 "WANDERING MERCHANT" $T.Muted
        Write-At 24 4 "Gold: $($Player.Gold)g" $T.Yellow

        for($i=0;$i -lt $stock.Count;$i++) {
            $item=Get-Item $stock[$i]
            $y=7+($i*2)

            if($i -eq $selected) {
                Write-At 24 $y "› $($item.Name.PadRight(27)) $($item.Value)g" (Rarity-Color $item.Rarity)
            } else {
                Write-At 24 $y "  $($item.Name.PadRight(27)) $($item.Value)g" $T.Text
            }
        }

        Write-At 24 24 "[ENTER] Buy   [ESC] Back" $T.Muted

        $key=[Console]::ReadKey($true)

        switch($key.Key) {
            "UpArrow" {$selected=[Math]::Max(0,$selected-1)}
            "DownArrow" {$selected=[Math]::Min($stock.Count-1,$selected+1)}
            "Enter" {
                $item=Get-Item $stock[$selected]

                if($Player.Gold -ge $item.Value) {
                    $Player.Gold-=$item.Value
                    Add-Item $item.Id
                    Add-Log "Bought $($item.Name) for $($item.Value)g."
                } else {
                    Add-Log "Not enough gold."
                }
            }
            "Escape" {return}
            "Q" {Exit-Game}
        }
    }
}

# ============================================================
# EVENT LOG
# ============================================================

function Log-Menu {
    while($true) {
        Clear-Screen
        Draw-Header "Event Log"
        Draw-Sidebar 9

        Write-At 24 3 "ADVENTURE LOG" $T.Muted

        $start=[Math]::Max(0,$Log.Count-17)

        for($i=$start;$i -lt $Log.Count;$i++) {
            $y=5+($i-$start)
            Write-At 24 $y (Truncate $Log[$i] 68) $T.Text
        }

        Write-At 24 24 "[ESC] Back" $T.Muted

        $key=[Console]::ReadKey($true)

        if($key.Key -eq "Escape"){return}
        if($key.Key -eq "Q"){Exit-Game}
    }
}

# ============================================================
# SAVE / LOAD
# ============================================================

$SaveFile = Join-Path $PSScriptRoot "rpg-save.json"

function Save-Game {
    try {
        $Player | ConvertTo-Json -Depth 10 | Set-Content -Path $SaveFile -Encoding UTF8
        Add-Log "Game saved."
    }
    catch {
        Add-Log "Could not save game."
    }
}

function Load-Game {
    if(-not (Test-Path $SaveFile)) {
        Add-Log "No save file found."
        return
    }

    try {
        $loaded=Get-Content $SaveFile -Raw | ConvertFrom-Json

        $Player.Name=$loaded.Name
        $Player.Level=$loaded.Level
        $Player.XP=$loaded.XP
        $Player.XPNext=$loaded.XPNext
        $Player.HP=$loaded.HP
        $Player.MaxHP=$loaded.MaxHP
        $Player.MP=$loaded.MP
        $Player.MaxMP=$loaded.MaxMP
        $Player.Gold=$loaded.Gold
        $Player.Strength=$loaded.Strength
        $Player.Dexterity=$loaded.Dexterity
        $Player.Intelligence=$loaded.Intelligence
        $Player.Vitality=$loaded.Vitality
        $Player.Luck=$loaded.Luck
        $Player.Capacity=$loaded.Capacity
        $Player.Location=$loaded.Location

        $Player.Inventory=@{}
        foreach($p in $loaded.Inventory.PSObject.Properties) {
            $Player.Inventory[$p.Name]=[int]$p.Value
        }

        $Player.Stash=@{}
        foreach($p in $loaded.Stash.PSObject.Properties) {
            $Player.Stash[$p.Name]=[int]$p.Value
        }

        foreach($slot in @("Weapon","Armor","Helmet","Ring","Amulet")) {
            $Player.Equipment[$slot]=$loaded.Equipment.$slot
        }

        Add-Log "Game loaded."
    }
    catch {
        Add-Log "Save file appears to be invalid."
    }
}

# ============================================================
# THEME
# ============================================================

function Theme-Menu {
    $names=@("Catppuccin","Dark","Light","Nord")
    $selected=$names.IndexOf($ThemeName)

    while($true) {
        Clear-Screen
        Draw-Header "Theme"

        Write-At 24 4 "COLOR SCHEME" $T.Muted

        for($i=0;$i -lt $names.Count;$i++) {
            $y=7+$i

            if($i -eq $selected) {
                Write-At 24 $y "› $($names[$i])" $T.Lavender
            } else {
                Write-At 24 $y "  $($names[$i])" $T.Text
            }
        }

        Write-At 24 15 "Current: $ThemeName" $T.Muted
        Write-At 24 20 "[ENTER] Apply   [ESC] Cancel" $T.Muted

        $key=[Console]::ReadKey($true)

        switch($key.Key) {
            "UpArrow" {$selected=[Math]::Max(0,$selected-1)}
            "DownArrow" {$selected=[Math]::Min($names.Count-1,$selected+1)}
            "Enter" {
                $ThemeName=$names[$selected]
                $script:T=$Themes[$ThemeName]
                Add-Log "Theme changed to $ThemeName."
                return
            }
            "Escape" {return}
        }
    }
}

# ============================================================
# HELP
# ============================================================

function Help-Menu {
    Clear-Screen
    Draw-Header "Help"

    Write-At 24 4 "CONTROLS" $T.Muted

    $help=@(
        "↑ ↓ / W S     Navigate menus",
        "ENTER          Select / confirm",
        "ESC            Go back",
        "/              Search inventory",
        "S              Save game",
        "L              Load game",
        "T              Change theme",
        "?              Show help",
        "Q              Quit",
        "",
        "INVENTORY",
        "Equip weapons and armor.",
        "Use potions and manage your stash.",
        "",
        "HUNT",
        "Fight enemies to earn XP, gold and loot.",
        "",
        "CRAFTING",
        "Combine materials into better equipment.",
        "",
        "WORLD",
        "Travel between different locations."
    )

    for($i=0;$i -lt $help.Count;$i++) {
        Write-At 24 (6+$i) $help[$i] $T.Text
    }

    Write-At 24 28 "[ANY KEY] Back" $T.Muted
    [Console]::ReadKey($true) | Out-Null
}

# ============================================================
# INPUT
# ============================================================

function Read-Input($label) {
    [Console]::CursorVisible=$true

    Write-At 23 26 "$label`: " $T.Text

    $input=Read-Host

    [Console]::CursorVisible=$false

    return $input
}

# ============================================================
# MAIN DASHBOARD
# ============================================================

function Dashboard {
    $selected=0

    while($true) {
        Clear-Screen
        Draw-Header "Dashboard"
        Draw-Sidebar $selected

        # Center dashboard
        Write-At 24 3 "ADVENTURER'S CAMP" $T.Muted

        Write-At 24 5 "Welcome back, $($Player.Name)." $T.Pink
        Write-At 24 6 "Your journey continues in $($Player.Location)." $T.Text

        Draw-Line 24 8 40

        Write-At 24 10 "STATUS" $T.Muted
        Write-At 24 12 "HP       $($Player.HP)/$($Player.MaxHP)" $T.Red
        Write-At 24 13 "MP       $($Player.MP)/$($Player.MaxMP)" $T.Cyan
        Write-At 24 14 "XP       $($Player.XP)/$($Player.XPNext)" $T.Yellow
        Write-At 24 15 "Gold     $($Player.Gold)g" $T.Yellow

        Draw-Line 24 17 40

        Write-At 24 19 "LATEST EVENTS" $T.Muted

        $start=[Math]::Max(0,$Log.Count-3)

        for($i=$start;$i -lt $Log.Count;$i++) {
            Write-At 24 (21+($i-$start)) (Truncate "• $($Log[$i])" 48) $T.Text
        }

        # Right preview panel
        Write-At 68 3 "PREVIEW" $T.Muted
        Draw-Line 68 4 27

        Write-At 68 6 "EQUIPPED" $T.Muted

        foreach($pair in $Player.Equipment.GetEnumerator()) {
            $name=if($pair.Value){(Get-Item $pair.Value).Name}else{"—"}
            Write-At 68 (8+([array]::IndexOf(@("Weapon","Armor","Helmet","Ring","Amulet"),$pair.Key))) `
                "$($pair.Key.PadRight(9)) $name" $T.Text
        }

        Draw-Line 68 15 27

        Write-At 68 17 "BACKPACK" $T.Muted
        Write-At 68 19 "$(Get-InventoryWeight) / $($Player.Capacity) weight" $T.Text
        Write-At 68 21 "$($Player.Inventory.Count) item types" $T.Text
        Write-At 68 22 "$($Player.Stash.Count) stored types" $T.Text

        Write-At 68 25 "[ENTER] Open   [Q] Quit" $T.Muted

        $key=[Console]::ReadKey($true)

        switch($key.Key) {
            "UpArrow" {$selected=[Math]::Max(0,$selected-1)}
            "DownArrow" {$selected=[Math]::Min(9,$selected+1)}
            "Enter" {
                switch($selected) {
                    0 {Inventory-Menu}
                    1 {Equipment-Menu}
                    2 {Stash-Menu}
                    3 {Character-Menu}
                    4 {Crafting-Menu}
                    5 {Hunt-Menu}
                    6 {Quest-Menu}
                    7 {World-Menu}
                    8 {Merchant-Menu}
                    9 {Log-Menu}
                }
            }
            "S" {Save-Game}
            "L" {Load-Game}
            "T" {Theme-Menu}
            "?" {Help-Menu}
            "Q" {Exit-Game}
        }
    }
}

# ============================================================
# EXIT
# ============================================================

function Exit-Game {
    Save-Game
    [Console]::CursorVisible=$true
    [Console]::Write($Reset)
    Clear-Host
    Write-Host ""
    Write-Host "  Thanks for playing, $($Player.Name)." -ForegroundColor Magenta
    Write-Host "  Your adventure has been saved." -ForegroundColor DarkGray
    Write-Host ""
    exit
}

# ============================================================
# STARTUP
# ============================================================

try {
    [Console]::CursorVisible=$false
    [Console]::OutputEncoding=[System.Text.Encoding]::UTF8

    Clear-Screen

    # Splash
    Write-At 24 6 "╔══════════════════════════════════╗" $T.Lavender
    Write-At 24 7 "║        RPG INVENTORY TUI        ║" $T.Lavender
    Write-At 24 8 "║      THE ADVENTURER'S VAULT     ║" $T.Blue
    Write-At 24 9 "╚══════════════════════════════════╝" $T.Lavender

    Write-At 24 12 "Loading inventory..." $T.Muted
    Start-Sleep -Milliseconds 500

    if(Test-Path $SaveFile) {
        Write-At 24 13 "Save file detected." $T.Green
        Write-At 24 14 "Press ENTER to continue." $T.Text

        $key=[Console]::ReadKey($true)

        if($key.Key -eq "Enter") {
            Load-Game
        }
    }
    else {
        Write-At 24 13 "New adventure initialized." $T.Green
        Start-Sleep -Milliseconds 500
    }

    Dashboard
}
finally {
    [Console]::CursorVisible=$true
    [Console]::Write($Reset)
}
