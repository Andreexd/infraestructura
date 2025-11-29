#!/bin/bash
# Script de deployment para AWS EC2

echo "🚀 Iniciando deployment de SaaS AWS..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con color
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar si estamos en EC2
print_status "Verificando entorno..."

# Actualizar sistema
print_status "Actualizando sistema..."
sudo yum update -y

# Instalar Node.js
if ! command -v node &> /dev/null; then
    print_status "Instalando Node.js..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    source ~/.bashrc
    nvm install 18
    nvm use 18
    nvm alias default 18
else
    print_success "Node.js ya está instalado"
fi

# Instalar PM2
if ! command -v pm2 &> /dev/null; then
    print_status "Instalando PM2..."
    npm install -g pm2
else
    print_success "PM2 ya está instalado"
fi

# Verificar estructura del proyecto
if [ ! -d "app/server" ]; then
    print_error "Estructura del proyecto no encontrada. Asegúrate de estar en el directorio correcto."
    exit 1
fi

print_success "Estructura del proyecto encontrada"

# Instalar dependencias
print_status "Instalando dependencias de Node.js..."
cd app/server
npm install

# Verificar archivo .env
if [ ! -f ".env" ]; then
    print_warning "Archivo .env no encontrado. Creando template..."
    cat > .env << EOL
# Configuración de producción
DB_HOST=tu-rds-endpoint.region.rds.amazonaws.com
DB_USER=admin
DB_PASSWORD=tu-password-seguro
DB_NAME=saas_db
SESSION_SECRET=tu-clave-super-secreta-$(date +%s)
PORT=3000
NODE_ENV=production
EOL
    print_warning "⚠️  IMPORTANTE: Edita el archivo .env con tus credenciales reales"
    print_warning "    nano .env"
fi

# Configurar firewall (si es necesario)
print_status "Verificando configuración de firewall..."
if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-port=3000/tcp
    sudo firewall-cmd --reload
    print_success "Firewall configurado"
fi

# Detener aplicación existente si está corriendo
print_status "Deteniendo aplicación existente..."
pm2 delete saas-app 2>/dev/null || true

# Iniciar aplicación con PM2
print_status "Iniciando aplicación con PM2..."
pm2 start app.js --name saas-app

# Configurar PM2 para auto-inicio
print_status "Configurando auto-inicio de PM2..."
pm2 startup
pm2 save

# Mostrar status
print_success "¡Deployment completado!"
echo ""
print_status "Estado de la aplicación:"
pm2 status

echo ""
print_status "La aplicación debería estar disponible en:"
echo "  - http://localhost:3000"
echo "  - http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"

echo ""
print_warning "Próximos pasos:"
echo "  1. Editar .env con credenciales RDS reales"
echo "  2. Reiniciar aplicación: pm2 restart saas-app"
echo "  3. Configurar Security Groups para permitir puerto 3000"
echo "  4. Configurar SSL/HTTPS con certificados"
echo "  5. Configurar CloudFront y Route 53"

echo ""
print_status "Comandos útiles:"
echo "  - Ver logs: pm2 logs saas-app"
echo "  - Reiniciar: pm2 restart saas-app"
echo "  - Estado: pm2 status"
echo "  - Monitoreo: pm2 monit"

print_success "🎉 ¡Deployment de SaaS AWS completado!"