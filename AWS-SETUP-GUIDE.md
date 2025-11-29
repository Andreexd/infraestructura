# 🚀 Guía Paso a Paso: Configuración AWS

## Orden de Implementación Recomendado

### Paso 1: Configurar RDS (Base de Datos) 🗄️

1. **Crear Instancia RDS**:
   ```bash
   # En AWS Console > RDS > Create Database
   - Engine: MySQL 8.0
   - Template: Free Tier (para práctica)
   - Instance: db.t3.micro
   - Storage: 20GB SSD
   - Username: admin
   - Password: [generar seguro]
   ```

2. **Configurar Security Group RDS**:
   ```
   Type: MySQL/Aurora
   Port: 3306
   Source: Security Group del EC2 (que crearemos después)
   ```

3. **Obtener Endpoint**:
   ```
   Ejemplo: saas-db.xxxxx.region.rds.amazonaws.com
   ```

4. **Actualizar .env**:
   ```bash
   DB_HOST=tu-endpoint-rds.region.rds.amazonaws.com
   DB_USER=admin
   DB_PASSWORD=tu-password
   DB_NAME=saas_db
   ```

5. **Inicializar Base de Datos**:
   ```bash
   mysql -h tu-endpoint -u admin -p < database.sql
   ```

---

### Paso 2: Configurar EC2 (Servidor de Aplicación) 💻

1. **Lanzar Instancia EC2**:
   ```bash
   - AMI: Amazon Linux 2
   - Instance Type: t2.micro (Free Tier)
   - Key Pair: crear nueva o usar existente
   ```

2. **Configurar Security Group EC2**:
   ```
   SSH (22): Tu IP
   HTTP (80): Anywhere
   HTTPS (443): Anywhere
   Custom (3000): Anywhere (temporal para testing)
   ```

3. **Conectar y Configurar Servidor**:
   ```bash
   # Conectar por SSH
   ssh -i tu-key.pem ec2-user@tu-ip-publica
   
   # Actualizar sistema
   sudo yum update -y
   
   # Instalar Node.js
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   source ~/.bashrc
   nvm install 18
   nvm use 18
   
   # Instalar Git
   sudo yum install git -y
   ```

4. **Subir Código**:
   ```bash
   # Opción 1: Git (recomendado)
   git clone tu-repositorio
   
   # Opción 2: SCP
   scp -i tu-key.pem -r ./app ec2-user@tu-ip:/home/ec2-user/
   ```

5. **Configurar Aplicación**:
   ```bash
   cd app/server
   npm install
   npm install -g pm2
   
   # Editar .env con credenciales RDS
   nano .env
   
   # Ejecutar con PM2
   pm2 start app.js --name saas-app
   pm2 startup
   pm2 save
   ```

---

### Paso 3: Configurar S3 (Almacenamiento) 📦

1. **Crear Bucket S3**:
   ```bash
   # Nombre único: saas-aws-files-[tu-nombre]-[random]
   Bucket name: saas-aws-files-roque-2024
   Region: us-east-1
   ```

2. **Configurar Políticas de Bucket**:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "PublicReadGetObject",
         "Effect": "Allow",
         "Principal": "*",
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::tu-bucket-name/public/*"
       }
     ]
   }
   ```

3. **Configurar CORS**:
   ```json
   [
     {
       "AllowedHeaders": ["*"],
       "AllowedMethods": ["GET", "PUT", "POST"],
       "AllowedOrigins": ["http://localhost:3000", "http://tu-dominio.com"],
       "ExposeHeaders": []
     }
   ]
   ```

4. **Crear IAM Role para EC2**:
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
         "Resource": "arn:aws:s3:::tu-bucket/*"
       }
     ]
   }
   ```

---

### Paso 4: Configurar CloudFront (CDN) 🌐

1. **Crear Distribución CloudFront**:
   ```bash
   # En AWS Console > CloudFront > Create Distribution
   Origin Domain: tu-bucket-s3.amazonaws.com
   Origin Path: /public (para archivos estáticos)
   
   # Configurar comportamientos
   Default Behavior: S3 Origin
   /api/*: EC2 Origin (para API calls)
   ```

2. **Configurar Origins**:
   ```bash
   # Origin 1: S3
   Domain: tu-bucket.s3.amazonaws.com
   Path: /public
   
   # Origin 2: EC2  
   Domain: ec2-xx-xx-xx-xx.region.compute.amazonaws.com
   HTTP Port: 3000
   Protocol: HTTP Only
   ```

3. **Configurar SSL**:
   ```bash
   # Usar certificado SSL de CloudFront (*.cloudfront.net)
   # O crear certificado personalizado con ACM
   ```

---

### Paso 5: Configurar Route 53 (DNS) 🌍

1. **Opción A: Usar dominio gratuito (testing)**:
   ```bash
   # Usar subdominio gratuito como:
   # tu-app.freenom.tk
   # tu-app.github.io
   ```

2. **Opción B: Dominio personalizado**:
   ```bash
   # En Route 53 > Hosted Zones > Create
   Domain: tu-dominio.com
   
   # Crear registros
   A Record: @ -> CloudFront Distribution
   CNAME: www -> CloudFront Distribution
   ```

---

### Paso 6: Configurar Monitoreo y Logs 📊

1. **CloudWatch**:
   ```bash
   # Habilitar métricas básicas
   # Crear alarmas para CPU, memoria, errores
   ```

2. **CloudTrail**:
   ```bash
   # Habilitar auditoría de acciones AWS
   # Configurar bucket S3 para logs
   ```

---

## 🔧 Comandos de Testing

### Testing Local
```bash
# Probar aplicación local
curl http://localhost:3000
curl -X POST http://localhost:3000/api/register -d '{"username":"test","email":"test@example.com","password":"123456"}' -H "Content-Type: application/json"
```

### Testing Producción
```bash
# Probar EC2 directamente
curl http://tu-ip-ec2:3000

# Probar CloudFront
curl https://tu-distribution.cloudfront.net

# Probar dominio final
curl https://tu-dominio.com
```

---

## ⚠️ Checklist de Seguridad

- [ ] Security Groups configurados correctamente
- [ ] RDS no es público
- [ ] S3 bucket policies restrictivas
- [ ] IAM roles con permisos mínimos
- [ ] HTTPS habilitado
- [ ] SSH keys seguras
- [ ] Variables de entorno seguras
- [ ] Logs habilitados
- [ ] Backups automáticos de RDS

---

## 💰 Estimación de Costos (Free Tier)

| Servicio | Costo Estimado (Mensual) |
|----------|-------------------------|
| EC2 t2.micro | $0 (Free Tier) |
| RDS db.t3.micro | $0 (Free Tier primeros 12 meses) |
| S3 (5GB) | $0 (Free Tier) |
| CloudFront (1TB) | $0 (Free Tier) |
| Route 53 | $0.50 (hosted zone) |
| **Total** | **~$0.50/mes** |

---

## 📝 Notas Importantes

1. **Free Tier**: Dura 12 meses desde creación de cuenta AWS
2. **Límites**: Monitorear uso para no exceder Free Tier
3. **Región**: Usar us-east-1 para mejor compatibilidad
4. **Backup**: Configurar snapshots de RDS
5. **Dominio**: Si no tienes dominio, usar CloudFront URL

---

## 🎯 Orden de Prioridad para la Práctica

1. **Alto**: RDS + EC2 (20 + 15 = 35 pts)
2. **Medio**: S3 + CloudFront (10 + 10 = 20 pts)  
3. **Bajo**: Route 53 (5 pts)
4. **Crítico**: Seguridad + Documentación (15 + 10 = 25 pts)

**Total posible: 95-100 pts** 🎉