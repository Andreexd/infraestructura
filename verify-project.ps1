# Script PowerShell simplificado para verificar el proyecto
Write-Host "Verificando proyecto SaaS AWS..." -ForegroundColor Blue

# Verificar Node.js
try {
    $nodeVersion = node --version
    Write-Host "Node.js instalado: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "Node.js no está instalado" -ForegroundColor Red
    exit 1
}

# Verificar estructura
if (Test-Path "app\server") {
    Write-Host "Estructura del proyecto encontrada" -ForegroundColor Green
    
    # Verificar archivos importantes
    if (Test-Path "app\server\package.json") {
        Write-Host "package.json encontrado" -ForegroundColor Green
    }
    if (Test-Path "app\server\app.js") {
        Write-Host "app.js encontrado" -ForegroundColor Green
    }
    if (Test-Path "app\public\index.html") {
        Write-Host "index.html encontrado" -ForegroundColor Green
    }
    
} else {
    Write-Host "Estructura del proyecto no encontrada" -ForegroundColor Red
    exit 1
}

Write-Host "`nResumen del proyecto:" -ForegroundColor Cyan
Write-Host "- Aplicacion web con login/register/dashboard" -ForegroundColor White
Write-Host "- Backend: Node.js + Express + MySQL" -ForegroundColor White
Write-Host "- Frontend: HTML + Bootstrap + JavaScript" -ForegroundColor White
Write-Host "- Listo para deployment en AWS" -ForegroundColor White

Write-Host "`nPara probar localmente:" -ForegroundColor Cyan
Write-Host "  cd app\server" -ForegroundColor Yellow
Write-Host "  npm install" -ForegroundColor Yellow
Write-Host "  npm start" -ForegroundColor Yellow

Write-Host "`nProyecto verificado exitosamente!" -ForegroundColor Green