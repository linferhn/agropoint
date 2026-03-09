#!/bin/bash
# ─── AgroPoint Pro — Script de configuración MySQL ───────────────────────────
# Ejecutar: bash setup_mysql.sh

echo "🌾 AgroPoint Pro — Configuración de Base de Datos MySQL"
echo "════════════════════════════════════════════════════════"

read -p "Host MySQL [localhost]: " DB_HOST
DB_HOST=${DB_HOST:-localhost}

read -p "Puerto MySQL [3306]: " DB_PORT
DB_PORT=${DB_PORT:-3306}

read -p "Usuario root MySQL: " ROOT_USER
ROOT_USER=${ROOT_USER:-root}

read -s -p "Contraseña root MySQL: " ROOT_PASS
echo ""

echo ""
echo "📦 Creando base de datos y usuario..."

mysql -h "$DB_HOST" -P "$DB_PORT" -u "$ROOT_USER" -p"$ROOT_PASS" << SQL
CREATE DATABASE IF NOT EXISTS agropoint CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'agropoint'@'%' IDENTIFIED BY 'agropoint123';
GRANT ALL PRIVILEGES ON agropoint.* TO 'agropoint'@'%';
FLUSH PRIVILEGES;
SQL

if [ $? -eq 0 ]; then
    echo "✅ Base de datos creada exitosamente"
    echo ""
    echo "📋 Aplicando esquema..."
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$ROOT_USER" -p"$ROOT_PASS" agropoint < schema.sql
    echo "✅ Esquema aplicado"
    echo ""
    echo "🔧 Creando archivo .env..."
    cat > .env << ENV
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_USER=agropoint
DB_PASSWORD=agropoint123
DB_NAME=agropoint
PORT=5000
FLASK_DEBUG=false
ENV
    echo "✅ .env creado"
    echo ""
    echo "🚀 Para iniciar la aplicación:"
    echo "   pip install -r requirements.txt"
    echo "   python app.py"
    echo ""
    echo "   O con Gunicorn (producción):"
    echo "   gunicorn --bind 0.0.0.0:5000 --workers 4 app:app"
    echo ""
    echo "   O con Docker:"
    echo "   docker-compose up -d"
else
    echo "❌ Error al crear la base de datos"
    exit 1
fi
