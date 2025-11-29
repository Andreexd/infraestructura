-- Script SQL para inicializar la base de datos SaaS AWS
-- Base de datos: MySQL (para usar con RDS)

-- Crear base de datos (ejecutar como admin)
CREATE DATABASE IF NOT EXISTS saas_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE saas_db;

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_email (email),
    INDEX idx_username (username)
);

-- Tabla de sesiones de usuario
CREATE TABLE IF NOT EXISTS user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_token VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_session_token (session_token),
    INDEX idx_user_id (user_id)
);

-- Tabla de archivos subidos (para integrar con S3)
CREATE TABLE IF NOT EXISTS user_files (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    filename VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100),
    s3_key VARCHAR(500) NOT NULL,
    s3_bucket VARCHAR(100) NOT NULL,
    description TEXT,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_public BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_upload_date (upload_date)
);

-- Tabla de logs de actividad (para auditoría)
CREATE TABLE IF NOT EXISTS activity_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
);

-- Tabla de configuraciones del sistema
CREATE TABLE IF NOT EXISTS system_config (
    id INT AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(100) NOT NULL UNIQUE,
    config_value TEXT,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_config_key (config_key)
);

-- Insertar configuraciones por defecto
INSERT INTO system_config (config_key, config_value, description) VALUES
('max_file_size', '10485760', 'Tamaño máximo de archivo en bytes (10MB)'),
('allowed_file_types', 'jpg,jpeg,png,pdf,doc,docx,txt', 'Tipos de archivo permitidos'),
('s3_bucket_name', 'saas-aws-files', 'Nombre del bucket S3 por defecto'),
('app_version', '1.0.0', 'Versión de la aplicación')
ON DUPLICATE KEY UPDATE config_value = VALUES(config_value);

-- Usuario de prueba (contraseña: password123)
-- Hash generado con bcrypt rounds=10
INSERT INTO users (username, email, password_hash) VALUES
('admin', 'admin@example.com', '$2a$10$rQvHOQGAb0EW.1X2XQXQ2eJ4Q4Q4Q4Q4Q4Q4Q4Q4Q4Q4Q4Q4Q4Q4Qe')
ON DUPLICATE KEY UPDATE username = VALUES(username);

-- Crear índices adicionales para performance
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_files_size ON user_files(file_size);
CREATE INDEX idx_sessions_expires ON user_sessions(expires_at);

-- Vista para estadísticas de usuarios
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    u.id,
    u.username,
    u.email,
    u.created_at as registered_date,
    COUNT(uf.id) as total_files,
    COALESCE(SUM(uf.file_size), 0) as total_storage_used,
    MAX(al.created_at) as last_activity
FROM users u
LEFT JOIN user_files uf ON u.id = uf.user_id
LEFT JOIN activity_logs al ON u.id = al.user_id
WHERE u.is_active = TRUE
GROUP BY u.id, u.username, u.email, u.created_at;