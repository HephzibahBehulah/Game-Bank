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
  @{ Name = "08 FUSE BOX"; Path = "game8/" }
)
$utf8 = New-Object System.Text.UTF8Encoding($false)
$crlf = [char]13 + [char]10
foreach ($game in $games) {
  $url = $BaseUrl.TrimEnd("/") + "/" + $game.Path
  $content = "[InternetShortcut]" + $crlf + "URL=" + $url + $crlf
  [System.IO.File]::WriteAllText((Join-Path $folder ($game.Name + ".url")), $content, $utf8)
}
Write-Host "Created $($games.Count) Game Bank launchers in $folder"
