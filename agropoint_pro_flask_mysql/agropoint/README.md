# 🌾 AgroPoint Pro — Sistema de Gestión Agrícola

Sistema completo de punto de venta e inventario para distribuidoras agrícolas.
**Python Flask + MySQL** (convertido desde versión frontend con IndexedDB).

---

## 📋 Características

- **POS** — Punto de venta con múltiples niveles de precio y descuentos
- **Inventario** — Control de stock con alertas de mínimos
- **Clientes** — Gestión de crédito y límites
- **Proveedores** — Facturas de compra y cuentas por pagar
- **Caja** — Sesiones de caja y movimientos
- **Reportes** — Ventas, ganancias y análisis
- **Contabilidad** — Plan de cuentas e impuestos Honduras
- **Usuarios** — Roles: admin, cajero, almacén, compras

---

## 🚀 Instalación Rápida

### Opción 1: Script automático (Recomendado)

```bash
# 1. Configurar MySQL
bash setup_mysql.sh

# 2. Instalar dependencias Python
pip install -r requirements.txt

# 3. Iniciar
python app.py
```

Abrir navegador en: **http://localhost:5000**

---

### Opción 2: Manual

**Requisitos:** Python 3.9+, MySQL 5.7+ o MariaDB 10.3+

```bash
# 1. Crear base de datos MySQL
mysql -u root -p
  CREATE DATABASE agropoint CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  CREATE USER 'agropoint'@'%' IDENTIFIED BY 'agropoint123';
  GRANT ALL PRIVILEGES ON agropoint.* TO 'agropoint'@'%';
  FLUSH PRIVILEGES;
  EXIT;

# 2. Aplicar esquema
mysql -u root -p agropoint < schema.sql

# 3. Configurar .env
cp .env.example .env
# Editar .env con los datos de tu servidor

# 4. Instalar dependencias
pip install -r requirements.txt

# 5. Iniciar servidor
python app.py
```

---

### Opción 3: Docker Compose

```bash
docker-compose up -d
```

Esto inicia automáticamente:
- MySQL 8.0 con datos iniciales
- Flask en puerto 5000

---

## 🔐 Usuarios por Defecto

| Usuario  | Contraseña | Rol      |
|----------|-----------|----------|
| admin    | 1234      | Admin    |
| cajero   | 1234      | Cajero   |
| almacen  | 1234      | Almacén  |
| compras  | 1234      | Compras  |

> ⚠️ **Cambiar contraseñas en Configuración > Usuarios antes de producción**

---

## 🗄️ Base de Datos

### Tablas Principales

| Tabla              | Descripción                    |
|--------------------|--------------------------------|
| `users`            | Usuarios del sistema           |
| `products`         | Catálogo de productos          |
| `clients`          | Clientes y créditos            |
| `suppliers`        | Proveedores                    |
| `sales`            | Ventas/Facturas                |
| `sale_items`       | Detalle de ventas              |
| `purchases`        | Compras a proveedores          |
| `purchase_items`   | Detalle de compras             |
| `cash_sessions`    | Sesiones de caja               |
| `cash_movements`   | Movimientos de caja            |
| `credit_payments`  | Pagos a crédito                |
| `config`           | Configuración del sistema      |

---

## 🌐 API REST

| Método | Endpoint              | Descripción              |
|--------|-----------------------|--------------------------|
| POST   | `/api/login`          | Autenticación            |
| GET    | `/api/{store}`        | Obtener todos los registros |
| POST   | `/api/{store}`        | Crear/actualizar registro |
| DELETE | `/api/{store}/{id}`   | Eliminar registro        |
| GET    | `/api/config/{key}`   | Obtener configuración    |
| PUT    | `/api/config/{key}`   | Guardar configuración    |
| GET    | `/api/health`         | Estado del servidor      |
| GET    | `/api/dashboard`      | Resumen del dashboard    |

---

## 🖥️ Producción con Nginx

```nginx
server {
    listen 80;
    server_name tudominio.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Iniciar con Gunicorn:
```bash
gunicorn --bind 0.0.0.0:5000 --workers 4 --timeout 120 app:app
```

---

## 📁 Estructura de Archivos

```
agropoint/
├── app.py              # Backend Flask (API REST)
├── schema.sql          # Esquema MySQL + datos iniciales
├── requirements.txt    # Dependencias Python
├── docker-compose.yml  # Deploy con Docker
├── Dockerfile
├── setup_mysql.sh      # Script configuración MySQL
├── .env.example        # Plantilla de configuración
└── static/
    └── index.html      # Frontend (HTML/JS/CSS)
```

---

## ⚙️ Variables de Entorno (.env)

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=agropoint
DB_PASSWORD=agropoint123
DB_NAME=agropoint
PORT=5000
FLASK_DEBUG=false
```
