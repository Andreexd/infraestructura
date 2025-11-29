# SaaS AWS - Proyecto de Infraestructura de Servicios

## 📋 Descripción del Proyecto

Implementación de una aplicación SaaS (Software como Servicio) escalable y segura utilizando servicios gestionados de AWS. La aplicación consiste en un sistema de autenticación con dashboard de usuario que permite subir y gestionar archivos.

## 🏗️ Arquitectura AWS Planificada

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Route 53      │    │   CloudFront    │    │      EC2        │
│   DNS           │────▶│   CDN           │────▶│   App Server    │
│   Dominio       │    │   Global        │    │   Node.js       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│       S3        │    │      RDS        │    │      IAM        │
│   Static Files  │    │     MySQL       │    │   Security      │
│   User Uploads  │    │   Database      │    │   Roles         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Servicios AWS y sus Roles

| Servicio | Rol en el Proyecto | Puerto/Config |
|----------|-------------------|---------------|
| **EC2** | Servidor de aplicación (Node.js + Express) | Puerto 3000/80/443 |
| **S3** | Almacenamiento de archivos estáticos y uploads | HTTPS |
| **RDS** | Base de datos MySQL para usuarios y archivos | Puerto 3306 |
| **CloudFront** | CDN para distribución global de contenido | HTTPS |
| **Route 53** | Gestión DNS del dominio personalizado | - |
| **IAM** | Gestión de permisos y roles de seguridad | - |

## 🔧 Stack Tecnológico

- **Backend**: Node.js + Express.js
- **Frontend**: HTML5 + CSS3 + Bootstrap 5 + JavaScript Vanilla
- **Base de Datos**: MySQL 8.0 (RDS)
- **Autenticación**: bcryptjs + express-session
- **Almacenamiento**: AWS S3
- **CDN**: AWS CloudFront

## 📁 Estructura del Proyecto

```
app/
├── server/
│   ├── app.js              # Servidor principal Express
│   ├── package.json        # Dependencias Node.js
│   ├── .env               # Variables de entorno
│   └── database.sql       # Script de inicialización DB
└── public/
    ├── index.html         # Página principal
    ├── login.html         # Página de login
    ├── register.html      # Página de registro
    ├── dashboard.html     # Dashboard de usuario
    ├── style.css          # Estilos personalizados
    └── script.js          # JavaScript del frontend
```

## 🚀 Instrucciones de Deployment

### Paso 1: Configuración Local (Desarrollo)

1. **Instalar dependencias**:
   ```bash
   cd app/server
   npm install
   ```

2. **Configurar variables de entorno**:
   - Editar `.env` con las credenciales de RDS cuando esté disponible

3. **Ejecutar en desarrollo**:
   ```bash
   npm start
   ```
   - Aplicación disponible en: http://localhost:3000

### Paso 2: Configuración AWS (Producción)

#### A. Configurar RDS (Base de Datos)
1. Crear instancia RDS MySQL 8.0
2. Configurar security groups (puerto 3306)
3. Ejecutar `database.sql` para inicializar tablas
4. Actualizar `.env` con endpoint RDS

#### B. Configurar EC2 (Servidor)
1. Lanzar instancia EC2 (Amazon Linux 2)
2. Instalar Node.js y npm
3. Configurar security groups (puertos 22, 80, 443, 3000)
4. Subir código y ejecutar aplicación
5. Configurar proceso con PM2 o systemd

#### C. Configurar S3 (Almacenamiento)
1. Crear bucket S3 para archivos estáticos
2. Configurar políticas de acceso público limitado
3. Habilitar CORS para uploads desde la aplicación
4. Configurar cifrado en reposo

#### D. Configurar CloudFront (CDN)
1. Crear distribución CloudFront
2. Configurar origen hacia S3 y/o EC2
3. Configurar HTTPS obligatorio
4. Optimizar para contenido estático

#### E. Configurar Route 53 (DNS)
1. Registrar o transferir dominio
2. Crear hosted zone
3. Configurar registros A/CNAME hacia CloudFront
4. Verificar propagación DNS

#### F. Configurar Seguridad (IAM)
1. Crear roles IAM específicos para EC2
2. Políticas mínimas para S3 y RDS
3. Configurar AWS CLI con credenciales limitadas

## 🔒 Configuraciones de Seguridad

### Security Groups
- **EC2**: Permitir SSH (22), HTTP (80), HTTPS (443)
- **RDS**: Permitir MySQL (3306) solo desde EC2
- **S3**: Políticas de bucket restrictivas

### Cifrado
- **En tránsito**: HTTPS/SSL en todos los servicios
- **En reposo**: RDS cifrado + S3 cifrado
- **Passwords**: bcrypt con salt rounds 10

### IAM Roles (Principio de menor privilegio)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::tu-bucket-name/*"
    }
  ]
}
```

## 📊 Funcionalidades Implementadas

### ✅ Completado
- [x] Sistema de registro y login
- [x] Dashboard de usuario responsivo
- [x] Estructura de base de datos MySQL
- [x] Validaciones de frontend y backend
- [x] Manejo de sesiones seguro
- [x] Logs de actividad de usuarios
- [x] Preparación para integración S3
- [x] API REST completa

### 🔄 Próximos Pasos (Configuración AWS)
- [ ] Configurar RDS MySQL
- [ ] Configurar EC2 con aplicación
- [ ] Configurar S3 para archivos
- [ ] Implementar subida de archivos
- [ ] Configurar CloudFront
- [ ] Configurar Route 53
- [ ] Implementar monitoreo y logs

## 🎯 Criterios de Evaluación Cubiertos

| Criterio | Estado | Puntuación |
|----------|--------|------------|
| Arquitectura funcional | ✅ Planificada | 20 pts |
| Configuración EC2 | 🔄 Pendiente AWS | 15 pts |
| Configuración S3 | 🔄 Pendiente AWS | 10 pts |
| RDS funcional y seguro | ✅ Scripts listos | 10 pts |
| CloudFront funcional | 🔄 Pendiente AWS | 10 pts |
| DNS configurado | 🔄 Pendiente dominio | 5 pts |
| Seguridad general | ✅ Implementada | 15 pts |
| Documentación técnica | ✅ Completa | 10 pts |
| Presentación final | 🔄 Pendiente | 5 pts |

## 📝 Variables de Entorno Necesarias

```bash
# Base de datos
DB_HOST=tu-rds-endpoint.region.rds.amazonaws.com
DB_USER=admin
DB_PASSWORD=tu-password-seguro
DB_NAME=saas_db

# Sesiones
SESSION_SECRET=tu-clave-super-secreta

# AWS (opcional, usar IAM roles)
AWS_ACCESS_KEY_ID=tu-access-key
AWS_SECRET_ACCESS_KEY=tu-secret-key
AWS_REGION=us-east-1
S3_BUCKET_NAME=tu-bucket-name

# Aplicación
PORT=3000
NODE_ENV=production
```

## 🚨 Notas Importantes

1. **Seguridad**: Nunca commitear credenciales reales en el código
2. **Costos**: Monitorear uso de servicios AWS
3. **Backup**: Configurar backups automáticos de RDS
4. **SSL**: Configurar certificados SSL gratuitos con Let's Encrypt
5. **Monitoring**: Implementar CloudWatch para monitoreo

## 📞 Comandos Útiles

```bash
# Desarrollo local
npm start                    # Iniciar servidor
npm install                  # Instalar dependencias

# Producción EC2
sudo systemctl start nodejs  # Iniciar servicio
sudo systemctl enable nodejs # Habilitar auto-inicio
pm2 start app.js --name saas # Usar PM2

# Base de datos
mysql -h endpoint -u admin -p < database.sql
```

---

**Proyecto desarrollado para la práctica de Infraestructura de Servicios**  
*Implementación de SaaS escalable y seguro en AWS*