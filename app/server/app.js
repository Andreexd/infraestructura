const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');
const session = require('express-session');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, '../public')));

// Sesiones
app.use(session({
  secret: process.env.SESSION_SECRET || 'aws-saas-secret-key',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false } // En producción cambiar a true con HTTPS
}));

// Configuración de base de datos (pendiente RDS)
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'saas_db'
};

let db = null;

// Solo intentar conectar si no son los valores por defecto
if (process.env.DB_HOST && process.env.DB_HOST !== 'your-rds-endpoint.region.rds.amazonaws.com') {
  try {
    db = mysql.createConnection(dbConfig);
    db.on('error', (err) => {
      console.log('Database connection error:', err.message);
      db = null;
    });
    console.log('Database connection configured');
  } catch (error) {
    console.log('Database connection failed - running in development mode');
    db = null;
  }
} else {
  console.log('Database connection pending - will configure with RDS');
  console.log('Running in development mode without database');
}

// Rutas principales
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/index.html'));
});

app.get('/login', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/login.html'));
});

app.get('/register', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/register.html'));
});

app.get('/dashboard', (req, res) => {
  if (req.session.userId) {
    res.sendFile(path.join(__dirname, '../public/dashboard.html'));
  } else {
    res.redirect('/login');
  }
});

// Función para registrar actividad
function logActivity(userId, action, details, req) {
  if (!db) return;
  
  const query = `
    INSERT INTO activity_logs (user_id, action, details, ip_address, user_agent)
    VALUES (?, ?, ?, ?, ?)
  `;
  
  const ip = req.ip || req.connection.remoteAddress;
  const userAgent = req.headers['user-agent'] || '';
  
  db.execute(query, [userId, action, details, ip, userAgent], (err) => {
    if (err) console.log('Error logging activity:', err);
  });
}

// API Routes
app.post('/api/register', async (req, res) => {
  try {
    const { username, email, password } = req.body;
    
    // Validaciones
    if (!username || !email || !password) {
      return res.status(400).json({ 
        success: false, 
        message: 'Todos los campos son requeridos' 
      });
    }
    
    if (password.length < 6) {
      return res.status(400).json({ 
        success: false, 
        message: 'La contraseña debe tener al menos 6 caracteres' 
      });
    }
    
    const hashedPassword = await bcrypt.hash(password, 10);
    
    if (db) {
      // Verificar si el usuario ya existe
      const checkQuery = 'SELECT id FROM users WHERE email = ? OR username = ?';
      db.execute(checkQuery, [email, username], (err, results) => {
        if (err) {
          console.error('Database error:', err);
          return res.status(500).json({ 
            success: false, 
            message: 'Error de base de datos' 
          });
        }
        
        if (results.length > 0) {
          return res.status(400).json({ 
            success: false, 
            message: 'El usuario o email ya existe' 
          });
        }
        
        // Insertar nuevo usuario
        const insertQuery = `
          INSERT INTO users (username, email, password_hash) 
          VALUES (?, ?, ?)
        `;
        
        db.execute(insertQuery, [username, email, hashedPassword], (err, result) => {
          if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ 
              success: false, 
              message: 'Error al crear usuario' 
            });
          }
          
          logActivity(result.insertId, 'USER_REGISTERED', `Usuario ${username} registrado`, req);
          res.json({ success: true, message: 'Usuario registrado correctamente' });
        });
      });
    } else {
      // Modo sin base de datos (desarrollo)
      console.log('User registration (no DB):', { username, email });
      res.json({ success: true, message: 'Usuario registrado correctamente (modo desarrollo)' });
    }
    
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ success: false, message: 'Error en el registro' });
  }
});

app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ 
        success: false, 
        message: 'Email y contraseña son requeridos' 
      });
    }
    
    if (db) {
      // Buscar usuario en base de datos
      const query = 'SELECT id, username, email, password_hash FROM users WHERE email = ? AND is_active = TRUE';
      
      db.execute(query, [email], async (err, results) => {
        if (err) {
          console.error('Database error:', err);
          return res.status(500).json({ 
            success: false, 
            message: 'Error de base de datos' 
          });
        }
        
        if (results.length === 0) {
          return res.status(401).json({ 
            success: false, 
            message: 'Credenciales inválidas' 
          });
        }
        
        const user = results[0];
        const passwordMatch = await bcrypt.compare(password, user.password_hash);
        
        if (!passwordMatch) {
          return res.status(401).json({ 
            success: false, 
            message: 'Credenciales inválidas' 
          });
        }
        
        // Login exitoso
        req.session.userId = user.id;
        req.session.userEmail = user.email;
        req.session.username = user.username;
        
        logActivity(user.id, 'USER_LOGIN', `Login exitoso para ${user.email}`, req);
        res.json({ success: true, message: 'Login exitoso' });
      });
    } else {
      // Modo sin base de datos (desarrollo)
      console.log('User login attempt (no DB):', { email });
      
      // Simulación temporal
      req.session.userId = 1;
      req.session.userEmail = email;
      req.session.username = 'Usuario Demo';
      
      res.json({ success: true, message: 'Login exitoso (modo desarrollo)' });
    }
    
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, message: 'Error en el login' });
  }
});

app.post('/api/logout', (req, res) => {
  const userId = req.session.userId;
  
  if (userId) {
    logActivity(userId, 'USER_LOGOUT', 'Logout exitoso', req);
  }
  
  req.session.destroy((err) => {
    if (err) {
      return res.status(500).json({ success: false, message: 'Error al cerrar sesión' });
    }
    res.json({ success: true, message: 'Logout exitoso' });
  });
});

// API para obtener información del usuario
app.get('/api/user/info', (req, res) => {
  if (!req.session.userId) {
    return res.status(401).json({ success: false, message: 'No autenticado' });
  }
  
  if (db) {
    const query = `
      SELECT u.id, u.username, u.email, u.created_at,
             COUNT(uf.id) as total_files,
             COALESCE(SUM(uf.file_size), 0) as total_storage
      FROM users u
      LEFT JOIN user_files uf ON u.id = uf.user_id
      WHERE u.id = ?
      GROUP BY u.id, u.username, u.email, u.created_at
    `;
    
    db.execute(query, [req.session.userId], (err, results) => {
      if (err) {
        console.error('Database error:', err);
        return res.status(500).json({ success: false, message: 'Error de base de datos' });
      }
      
      if (results.length === 0) {
        return res.status(404).json({ success: false, message: 'Usuario no encontrado' });
      }
      
      const user = results[0];
      res.json({ 
        success: true, 
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          registeredDate: user.created_at,
          totalFiles: user.total_files,
          totalStorage: user.total_storage
        }
      });
    });
  } else {
    // Modo sin base de datos
    res.json({ 
      success: true, 
      user: {
        id: req.session.userId,
        username: req.session.username || 'Usuario Demo',
        email: req.session.userEmail,
        registeredDate: new Date(),
        totalFiles: 0,
        totalStorage: 0
      }
    });
  }
});

// API para obtener archivos del usuario
app.get('/api/user/files', (req, res) => {
  if (!req.session.userId) {
    return res.status(401).json({ success: false, message: 'No autenticado' });
  }
  
  if (db) {
    const query = `
      SELECT id, filename, original_name, file_size, mime_type, 
             description, upload_date, is_public
      FROM user_files 
      WHERE user_id = ? 
      ORDER BY upload_date DESC
      LIMIT 50
    `;
    
    db.execute(query, [req.session.userId], (err, results) => {
      if (err) {
        console.error('Database error:', err);
        return res.status(500).json({ success: false, message: 'Error de base de datos' });
      }
      
      res.json({ success: true, files: results });
    });
  } else {
    // Modo sin base de datos
    res.json({ success: true, files: [] });
  }
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
  console.log(`Visita: http://localhost:${PORT}`);
});