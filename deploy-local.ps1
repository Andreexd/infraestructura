# Script PowerShell para deployment local y preparación para AWS
# deploy-local.ps1

Write-Host "🚀 Iniciando preparación de SaaS AWS..." -ForegroundColor Blue

# Función para imprimir con colores
function Write-Status {
    param($Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param($Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Verificar Node.js
Write-Status "Verificando Node.js..."
try {
    $nodeVersion = node --version
    Write-Success "Node.js instalado: $nodeVersion"
} catch {
    Write-Error "Node.js no está instalado. Descárgalo de https://nodejs.org/"
    exit 1
}

# Verificar npm
Write-Status "Verificando npm..."
try {
    $npmVersion = npm --version
    Write-Success "npm instalado: $npmVersion"
} catch {
    Write-Error "npm no está disponible"
    exit 1
}

# Cambiar al directorio del servidor
if (Test-Path "app\server") {
    Set-Location "app\server"
    Write-Success "Directorio del servidor encontrado"
} else {
    Write-Error "Directorio 'app\server' no encontrado"
    exit 1
}

# Instalar dependencias
Write-Status "Instalando dependencias..."
try {
    npm install
    Write-Success "Dependencias instaladas correctamente"
} catch {
    Write-Error "Error instalando dependencias"
    exit 1
}

# Verificar archivo .env
if (-not (Test-Path ".env")) {
    Write-Warning "Archivo .env no encontrado. Creando template..."
    $envContent = @"
# Configuración local/desarrollo
DB_HOST=your-rds-endpoint.region.rds.amazonaws.com
DB_USER=admin
DB_PASSWORD=your-secure-password
DB_NAME=saas_db
SESSION_SECRET=super-secret-key-$(Get-Date -Format "yyyyMMddHHmmss")
PORT=3000
NODE_ENV=development
"@
    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-Warning "⚠️  Archivo .env creado. Edítalo con tus credenciales cuando configures RDS"
}

# Verificar puerto disponible
Write-Status "Verificando puerto 3000..."
$port3000 = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
if ($port3000) {
    Write-Warning "Puerto 3000 en uso. La aplicación podría no iniciarse correctamente."
    Write-Status "Procesos usando puerto 3000:"
    Get-Process -Id $port3000.OwningProcess | Format-Table Name, Id, CPU
}

# Crear script de inicio
$startScript = @"
@echo off
echo Iniciando SaaS AWS en modo desarrollo...
cd /d "%~dp0"
npm start
pause
"@
$startScript | Out-File -FilePath "start-dev.bat" -Encoding ASCII
Write-Success "Script de inicio creado: start-dev.bat"

# Crear script para AWS
$awsScript = @"
#!/bin/bash
# Auto-generado por deploy-local.ps1
# Usar este script en EC2

echo "Preparando aplicación para AWS EC2..."

# Actualizar sistema
sudo yum update -y

# Instalar dependencias si no existen
if ! command -v node &> /dev/null; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    source ~/.bashrc
    nvm install 18
    nvm use 18
fi

# Ir al directorio
cd app/server

# Instalar dependencias
npm install

# Instalar PM2
npm install -g pm2

# Configurar variables de entorno para producción
echo "Configurando variables de entorno..."
sed -i 's/NODE_ENV=development/NODE_ENV=production/' .env

# Iniciar con PM2
pm2 start app.js --name saas-aws
pm2 startup
pm2 save

echo "Aplicación iniciada en EC2"
pm2 status
"@
$awsScript | Out-File -FilePath "deploy-to-ec2.sh" -Encoding UTF8
Write-Success "Script AWS creado: deploy-to-ec2.sh"

# Mostrar resumen
Write-Status "`n📋 Resumen del proyecto:"
Write-Host "  ✅ Dependencias instaladas" -ForegroundColor Green
Write-Host "  ✅ Archivo .env configurado" -ForegroundColor Green
Write-Host "  ✅ Scripts de deployment creados" -ForegroundColor Green

Write-Status "`n🚀 Para probar localmente:"
Write-Host "  npm start" -ForegroundColor Cyan
Write-Host "  O ejecuta: start-dev.bat" -ForegroundColor Cyan

Write-Status "`n☁️  Para deployment en AWS:"
Write-Host "  1. Configura RDS y obtén el endpoint" -ForegroundColor Yellow
Write-Host "  2. Actualiza .env con credenciales reales" -ForegroundColor Yellow
Write-Host "  3. Sube el código a EC2" -ForegroundColor Yellow
Write-Host "  4. Ejecuta deploy-to-ec2.sh en el servidor" -ForegroundColor Yellow

Write-Status "`n📊 Servicios AWS necesarios:"
Write-Host "  • EC2 (t2.micro)" -ForegroundColor Magenta
Write-Host "  • RDS (MySQL)" -ForegroundColor Magenta
Write-Host "  • S3 (archivos)" -ForegroundColor Magenta
Write-Host "  • CloudFront (CDN)" -ForegroundColor Magenta
Write-Host "  • Route 53 (DNS)" -ForegroundColor Magenta

Write-Status "`n🔗 URLs útiles:"
Write-Host "  • Documentación: README.md" -ForegroundColor Blue
Write-Host "  • Guía AWS: AWS-SETUP-GUIDE.md" -ForegroundColor Blue
Write-Host "  • Local: http://localhost:3000" -ForegroundColor Blue

Write-Success "`n🎉 ¡Proyecto preparado exitosamente!"
Write-Host "Ejecuta 'npm start' para probar la aplicación localmente" -ForegroundColor Green

# Volver al directorio original
Set-Location "..\.."