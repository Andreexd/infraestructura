// SaaS AWS - JavaScript Principal

// Función para mostrar alertas
function showAlert(message, type = 'info') {
    const alertContainer = document.getElementById('alertContainer');
    const alertId = 'alert-' + Date.now();
    
    const alertHTML = `
        <div id="${alertId}" class="alert alert-${type} alert-dismissible fade show" role="alert">
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    `;
    
    alertContainer.innerHTML = alertHTML;
    
    // Auto-hide después de 5 segundos
    setTimeout(() => {
        const alertElement = document.getElementById(alertId);
        if (alertElement) {
            const alert = new bootstrap.Alert(alertElement);
            alert.close();
        }
    }, 5000);
}

// Función para hacer requests a la API
async function apiRequest(url, method = 'GET', data = null) {
    const options = {
        method,
        headers: {
            'Content-Type': 'application/json',
        },
    };
    
    if (data) {
        options.body = JSON.stringify(data);
    }
    
    try {
        const response = await fetch(url, options);
        const result = await response.json();
        return result;
    } catch (error) {
        console.error('Error en API request:', error);
        throw error;
    }
}

// Manejo del formulario de login
document.addEventListener('DOMContentLoaded', function() {
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            
            if (!email || !password) {
                showAlert('Por favor completa todos los campos', 'warning');
                return;
            }
            
            try {
                const button = loginForm.querySelector('button[type="submit"]');
                const originalText = button.innerHTML;
                button.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Iniciando sesión...';
                button.disabled = true;
                
                const result = await apiRequest('/api/login', 'POST', { email, password });
                
                if (result.success) {
                    showAlert('Login exitoso. Redirigiendo...', 'success');
                    setTimeout(() => {
                        window.location.href = '/dashboard';
                    }, 1000);
                } else {
                    showAlert(result.message || 'Error en el login', 'danger');
                }
                
                button.innerHTML = originalText;
                button.disabled = false;
                
            } catch (error) {
                showAlert('Error de conexión. Intenta nuevamente.', 'danger');
                const button = loginForm.querySelector('button[type="submit"]');
                button.innerHTML = 'Iniciar Sesión';
                button.disabled = false;
            }
        });
    }
});

// Manejo del formulario de registro
document.addEventListener('DOMContentLoaded', function() {
    const registerForm = document.getElementById('registerForm');
    if (registerForm) {
        registerForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const username = document.getElementById('username').value;
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const confirmPassword = document.getElementById('confirmPassword').value;
            const terms = document.getElementById('terms').checked;
            
            // Validaciones
            if (!username || !email || !password || !confirmPassword) {
                showAlert('Por favor completa todos los campos', 'warning');
                return;
            }
            
            if (password.length < 6) {
                showAlert('La contraseña debe tener al menos 6 caracteres', 'warning');
                return;
            }
            
            if (password !== confirmPassword) {
                showAlert('Las contraseñas no coinciden', 'warning');
                return;
            }
            
            if (!terms) {
                showAlert('Debes aceptar los términos y condiciones', 'warning');
                return;
            }
            
            try {
                const button = registerForm.querySelector('button[type="submit"]');
                const originalText = button.innerHTML;
                button.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Creando cuenta...';
                button.disabled = true;
                
                const result = await apiRequest('/api/register', 'POST', {
                    username,
                    email,
                    password
                });
                
                if (result.success) {
                    showAlert('Cuenta creada exitosamente. Redirigiendo al login...', 'success');
                    setTimeout(() => {
                        window.location.href = '/login';
                    }, 2000);
                } else {
                    showAlert(result.message || 'Error en el registro', 'danger');
                }
                
                button.innerHTML = originalText;
                button.disabled = false;
                
            } catch (error) {
                showAlert('Error de conexión. Intenta nuevamente.', 'danger');
                const button = registerForm.querySelector('button[type="submit"]');
                button.innerHTML = 'Crear Cuenta';
                button.disabled = false;
            }
        });
    }
});

// Funciones del Dashboard
function logout() {
    if (confirm('¿Estás seguro de que quieres cerrar sesión?')) {
        apiRequest('/api/logout', 'POST')
            .then(() => {
                showAlert('Sesión cerrada exitosamente', 'success');
                setTimeout(() => {
                    window.location.href = '/';
                }, 1000);
            })
            .catch(() => {
                window.location.href = '/';
            });
    }
}

function openFileUpload() {
    const uploadModal = new bootstrap.Modal(document.getElementById('uploadModal'));
    uploadModal.show();
}

function editProfile() {
    showAlert('Funcionalidad de edición de perfil próximamente disponible', 'info');
}

// Manejo del formulario de subida de archivos
document.addEventListener('DOMContentLoaded', function() {
    const uploadForm = document.getElementById('uploadForm');
    if (uploadForm) {
        uploadForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const fileInput = document.getElementById('file');
            const file = fileInput.files[0];
            
            if (!file) {
                showAlert('Por favor selecciona un archivo', 'warning');
                return;
            }
            
            // Simulación de subida (cuando S3 esté configurado)
            showAlert('Funcionalidad de subida a S3 próximamente disponible', 'info');
            
            // Cerrar modal
            const uploadModal = bootstrap.Modal.getInstance(document.getElementById('uploadModal'));
            uploadModal.hide();
            
            // Limpiar formulario
            uploadForm.reset();
        });
    }
});

// Inicializar dashboard si estamos en esa página
document.addEventListener('DOMContentLoaded', function() {
    if (window.location.pathname === '/dashboard') {
        // Actualizar fecha de último acceso
        const lastAccessElement = document.getElementById('lastAccess');
        if (lastAccessElement) {
            const now = new Date();
            lastAccessElement.textContent = now.toLocaleDateString('es-ES');
        }
        
        // Agregar efecto de fade-in a las tarjetas
        const cards = document.querySelectorAll('.card');
        cards.forEach((card, index) => {
            setTimeout(() => {
                card.classList.add('fade-in');
            }, index * 100);
        });
    }
});

// Funciones utilitarias
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function formatDate(date) {
    return new Date(date).toLocaleDateString('es-ES', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    });
}

// Validación de email
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Escape HTML para prevenir XSS
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}