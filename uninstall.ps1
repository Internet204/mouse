$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Dest  = Join-Path $env:LOCALAPPDATA 'MouseAssistant'
$Files = @(
    'MouseAssistant.exe',
    'client.env.example'
)

if (-not (Test-Path $Dest)) {
    Write-Host "Папка не найдена: $Dest. Удалять нечего." -ForegroundColor Yellow
    return
}

Write-Host 'Останавливаю MouseAssistant...'
Get-Process MouseAssistant -ErrorAction SilentlyContinue | Stop-Process -Force

$allOk = $true
foreach ($name in $Files) {
    $path = Join-Path $Dest $name
    if (-not (Test-Path $path)) { continue }

    try {
        Remove-Item $path -Force
        Write-Host "Удалён: $name" -ForegroundColor Green
    }
    catch {
        Write-Host "Ошибка удаления $name : $($_.Exception.Message)" -ForegroundColor Red
        $allOk = $false
    }
}

Get-ChildItem $Dest -Filter '*.download' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$envFile = Join-Path $Dest 'client.env'
if (Test-Path $envFile) {
    $answer = Read-Host 'Удалить конфиг client.env (там SERVER_URL и AUTH_TOKEN)? [y/N]'
    if ($answer -match '^(y|д|yes|да)$') {
        try {
            Remove-Item $envFile -Force
            Write-Host 'Удалён: client.env' -ForegroundColor Green
        }
        catch {
            Write-Host "Ошибка удаления client.env : $($_.Exception.Message)" -ForegroundColor Red
            $allOk = $false
        }
    }
    else {
        Write-Host "Конфиг сохранён: $envFile" -ForegroundColor Yellow
    }
}

if (Test-Path $Dest) {
    if (-not (Get-ChildItem $Dest -Force)) {
        Remove-Item $Dest -Force
        Write-Host "Папка удалена: $Dest" -ForegroundColor Green
    }
}

if ($allOk) {
    Write-Host 'Готово: MouseAssistant удалён.' -ForegroundColor Green
}
else {
    Write-Host 'Удаление выполнено не полностью. Проверьте ошибки выше.' -ForegroundColor Red
}
