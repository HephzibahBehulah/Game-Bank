param([string]$BaseUrl = "https://hephzibahbehulah.github.io/Game-Bank/")
$ErrorActionPreference = "Stop"
$desktop = [Environment]::GetFolderPath("Desktop")
$folder = Join-Path $desktop "Game Bank Launchers"
New-Item -ItemType Directory -Force -Path $folder | Out-Null
$games = @(
  @{ Name = "01 NEON PULSE - LED Light Designer"; Path = "game1/" },
  @{ Name = "02 CIRCUIT RUSH - Wire the Power"; Path = "game2/" },
  @{ Name = "03 OHM HUNTER"; Path = "game3/" },
  @{ Name = "04 VOLT DODGE"; Path = "game4/" },
  @{ Name = "05 RESISTOR MATCH"; Path = "game5/" },
  @{ Name = "06 CAPACITOR CHARGE"; Path = "game6/" },
  @{ Name = "07 BINARY FLASH"; Path = "game7/" },
  @{ Name = "08 FUSE BOX"; Path = "game8/" },
  @{ Name = "09 GOAL LINE - Football Penalties"; Path = "game9/" },
  @{ Name = "10 APEX CIRCUIT - Racing"; Path = "game10/" },
  @{ Name = "11 WORLD FOOTBALL - Season Play"; Path = "game11/" },
  @{ Name = "12 CORTEX PRIME - IQ"; Path = "game12/" },
  @{ Name = "13 SYNAPSE SPRINT - Memory"; Path = "game13/" },
  @{ Name = "14 BILLIONAIRE CHALLENGE"; Path = "game14/" },
  @{ Name = "15 TACTICS GRID - AI Tactics Arena"; Path = "game15/" },
  @{ Name = "16 APEX STRATEGY - Race Engineer"; Path = "game16/" },
  @{ Name = "17 PENALTY PRO - Adaptive Shootout"; Path = "game17/" },
  @{ Name = "18 DEBATE ARENA - AI Debate"; Path = "game18/" },
  @{ Name = "19 CASEFILE - AI Detective"; Path = "game19/" },
  @{ Name = "20 MARKET DUEL - AI Trader"; Path = "game20/" },
  @{ Name = "21 AI ARENA - Six Model Competition"; Path = "game22/" },
  @{ Name = "22 LAST SIGNAL - Battle Royale"; Path = "game21/" }
)
$utf8 = New-Object System.Text.UTF8Encoding($false)
$crlf = [char]13 + [char]10
foreach ($game in $games) {
  $url = $BaseUrl.TrimEnd("/") + "/" + $game.Path
  $content = "[InternetShortcut]" + $crlf + "URL=" + $url + $crlf
  [System.IO.File]::WriteAllText((Join-Path $folder ($game.Name + ".url")), $content, $utf8)
}
Write-Host "Created $($games.Count) Game Bank launchers in $folder"
