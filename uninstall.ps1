$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Dest  = Join-Path $env:LOCALAPPDATA 'MouseAssistant'
$Files = @(
    'MouseAssistant.exe',
    'MouseAssistantServer.exe',
    'client.env.example',
    'client.log',
    'last-choice-target.json',
    'last-choice-target.png'
)

if (-not (Test-Path $Dest)) {
    Write-Host "Папка не найдена: $Dest. Удалять нечего." -ForegroundColor Yellow
    return
}

function Stop-Mouse {
    foreach ($name in 'MouseAssistant.exe', 'MouseAssistantServer.exe') {
        cmd /c "taskkill /F /T /IM $name >nul 2>&1"
    }
}

function Remove-Locked {
    param([string]$Path)

    for ($i = 0; $i -lt 20; $i++) {
        try {
            Remove-Item $Path -Force
            return $true
        }
        catch {
            Stop-Mouse
            Start-Sleep -Milliseconds 500
        }
    }
    return $false
}

Write-Host 'Останавливаю MouseAssistant...'
Stop-Mouse

$allOk = $true
foreach ($name in $Files) {
    $path = Join-Path $Dest $name
    if (-not (Test-Path $path)) { continue }

    if (Remove-Locked $path) {
        Write-Host "Удалён: $name" -ForegroundColor Green
    }
    else {
        Write-Host "Не удалось удалить $name : файл занят другим процессом" -ForegroundColor Red
        $allOk = $false
    }
}

Get-ChildItem $Dest -Filter '*.download' -ErrorAction SilentlyContinue | ForEach-Object {
    if (Remove-Locked $_.FullName) {
        Write-Host "Удалён: $($_.Name)" -ForegroundColor Green
    }
}

$envFile = Join-Path $Dest 'client.env'
if (Test-Path $envFile) {
    if (Remove-Locked $envFile) {
        Write-Host 'Удалён: client.env' -ForegroundColor Green
    }
    else {
        Write-Host 'Не удалось удалить client.env : файл занят другим процессом' -ForegroundColor Red
        $allOk = $false
    }
}

if (Test-Path $Dest) {
    if (-not (Get-ChildItem $Dest -Force)) {
        Remove-Item $Dest -Force
        Write-Host "Папка удалена: $Dest" -ForegroundColor Green
    }
    else {
        Write-Host "В папке остались файлы: $Dest" -ForegroundColor Yellow
    }
}

if ($allOk) {
    Write-Host 'Готово: MouseAssistant удалён.' -ForegroundColor Green
}
else {
    Write-Host 'Удаление выполнено не полностью. Проверьте ошибки выше.' -ForegroundColor Red
}
