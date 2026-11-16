# v0.22.0 (16/11/2026): só para desenvolvimento no Chrome/Edge. Baixa do GitHub o pacote mais novo do Chrome e
# do Edge (Releases chrome-edge-vX.Y.Z do fork), descompacta e grava por cima da pasta da extensão. Com a opção
# "Recarregar sozinha quando os arquivos mudarem" ligada nas configurações, a extensão se recarrega em até 1 minuto.
# Uso (no terminal, na pasta extensao-ifto):
#   npm run chrome-dev                      vigia o GitHub e atualiza a cada versão nova (Ctrl+C para parar)
#   powershell -ExecutionPolicy Bypass -File scripts/atualizar-chrome-dev.ps1 -Pasta "C:\caminho\da\pasta"
param(
  # Pasta carregada em chrome://extensions ou edge://extensions ("Carregar sem compactação").
  [string]$Pasta = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'extensao-ifto-chrome'),
  [string]$Repositorio = 'dcarvalho89/extensao-ifto',
  # Fica vigiando: confere o GitHub a cada $Intervalo segundos (o GitHub aceita 60 consultas por hora sem login).
  [switch]$Vigiar,
  [int]$Intervalo = 120
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$cabecalho = @{ 'User-Agent' = 'extensao-ifto-dev'; 'Accept' = 'application/vnd.github+json' }

function Versao-Instalada {
  $arquivo = Join-Path $Pasta 'manifest.json'
  if (-not (Test-Path $arquivo)) { return $null }
  return (Get-Content $arquivo -Raw -Encoding UTF8 | ConvertFrom-Json).version
}

# Release chrome-edge-vX.Y.Z de número mais alto, com o .zip.
function Ultima-Versao {
  $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repositorio/releases?per_page=30" -Headers $cabecalho
  $melhor = $null
  foreach ($r in $releases) {
    if ($r.tag_name -notmatch '^chrome-edge-v(\d+\.\d+\.\d+)$') { continue }
    $zip = $r.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1
    if (-not $zip) { continue }
    $v = [version]$Matches[1]
    if (-not $melhor -or $v -gt $melhor.versao) { $melhor = @{ versao = $v; url = $zip.browser_download_url } }
  }
  return $melhor
}

function Atualizar {
  $ultima = Ultima-Versao
  if (-not $ultima) { Write-Host 'Nenhuma versão do Chrome/Edge publicada no GitHub ainda.'; return }
  $instalada = Versao-Instalada
  if ($instalada -and [version]$instalada -ge $ultima.versao) { Write-Host "$(Get-Date -Format HH:mm:ss) Já está na versão mais nova ($instalada)."; return }
  Write-Host "$(Get-Date -Format HH:mm:ss) Baixando a versão $($ultima.versao) (instalada: $(if ($instalada) { $instalada } else { 'nenhuma' }))..."
  $temp = Join-Path ([IO.Path]::GetTempPath()) ('extensao-ifto-' + [guid]::NewGuid())
  New-Item -ItemType Directory -Force $temp | Out-Null
  try {
    $zip = Join-Path $temp 'pacote.zip'
    Invoke-WebRequest -Uri $ultima.url -OutFile $zip -Headers @{ 'User-Agent' = 'extensao-ifto-dev' } -UseBasicParsing
    $novos = Join-Path $temp 'arquivos'
    Expand-Archive -Path $zip -DestinationPath $novos -Force
    if (-not (Test-Path (Join-Path $novos 'manifest.json'))) { throw 'O pacote baixado não tem manifest.json.' }
    New-Item -ItemType Directory -Force $Pasta | Out-Null
    # Espelha: a pasta fica igual ao pacote (arquivos que saíram da extensão também saem da pasta).
    robocopy $novos $Pasta /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "A cópia dos arquivos falhou (robocopy $LASTEXITCODE)." }
    Write-Host "Pronto: versão $($ultima.versao) gravada em $Pasta."
    Write-Host 'Com "Recarregar sozinha" ligada, a extensão se recarrega em até 1 minuto; senão, clique em Recarregar em chrome://extensions. Depois aperte F5 nas páginas do SEI e do Compras IFTO.'
  } finally {
    Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
  }
}

Write-Host "Pasta da extensão: $Pasta"
if (-not $Vigiar) { Atualizar; exit 0 }
Write-Host "Vigiando $Repositorio a cada $Intervalo segundos. Ctrl+C para parar."
while ($true) {
  try { Atualizar } catch { Write-Host "$(Get-Date -Format HH:mm:ss) Falhou: $($_.Exception.Message) (tenta de novo no próximo intervalo)" }
  Start-Sleep -Seconds $Intervalo
}
