-- =============================================
--  AGROPOINT PRO - ESQUEMA MySQL
--  Compatible: MySQL 5.7+ / MariaDB 10.3+
-- =============================================

CREATE DATABASE IF NOT EXISTS agropoint CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE agropoint;

-- USUARIOS
CREATE TABLE IF NOT EXISTS users (
  id BIGINT PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  password VARCHAR(100) NOT NULL,
  name VARCHAR(100) NOT NULL,
  role ENUM('admin','cajero','almacen','compras') DEFAULT 'cajero',
  active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- PRODUCTOS
CREATE TABLE IF NOT EXISTS products (
  id BIGINT PRIMARY KEY,
  code VARCHAR(50),
  barcode VARCHAR(100),
  name VARCHAR(200) NOT NULL,
  category VARCHAR(100),
  icon VARCHAR(20) DEFAULT '📦',
  cost DECIMAL(12,2) DEFAULT 0,
  price DECIMAL(12,2) DEFAULT 0,
  stock DECIMAL(12,2) DEFAULT 0,
  min_stock DECIMAL(12,2) DEFAULT 5,
  unit VARCHAR(30) DEFAULT 'unidad',
  tiers JSON,
  active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_code (code),
  INDEX idx_category (category),
  INDEX idx_active (active)
);

-- CLIENTES
CREATE TABLE IF NOT EXISTS clients (
  id BIGINT PRIMARY KEY,
  code VARCHAR(50),
  name VARCHAR(200) NOT NULL,
  rtn VARCHAR(30),
  phone VARCHAR(30),
  email VARCHAR(100),
  city VARCHAR(100),
  type ENUM('Agricultor','Distribuidor','Empresa','General') DEFAULT 'General',
  credit_limit DECIMAL(12,2) DEFAULT 0,
  balance DECIMAL(12,2) DEFAULT 0,
  total_sales DECIMAL(12,2) DEFAULT 0,
  special_disc DECIMAL(5,2) DEFAULT 0,
  default_tier INT DEFAULT 0,
  notes TEXT,
  active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_name (name),
  INDEX idx_rtn (rtn)
);

-- PROVEEDORES
CREATE TABLE IF NOT EXISTS suppliers (
  id BIGINT PRIMARY KEY,
  code VARCHAR(50),
  name VARCHAR(200) NOT NULL,
  rtn VARCHAR(30),
  contact VARCHAR(100),
  phone VARCHAR(30),
  email VARCHAR(100),
  city VARCHAR(100),
  category VARCHAR(100),
  credit_days INT DEFAULT 0,
  credit_limit DECIMAL(12,2) DEFAULT 0,
  total_purchases DECIMAL(12,2) DEFAULT 0,
  balance DECIMAL(12,2) DEFAULT 0,
  rating VARCHAR(5) DEFAULT '3',
  active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- VENTAS
CREATE TABLE IF NOT EXISTS sales (
  id BIGINT PRIMARY KEY,
  sale_number VARCHAR(30),
  date DATETIME NOT NULL,
  client_id BIGINT,
  client_name VARCHAR(200),
  subtotal DECIMAL(12,2) DEFAULT 0,
  discount DECIMAL(12,2) DEFAULT 0,
  tax DECIMAL(12,2) DEFAULT 0,
  total DECIMAL(12,2) DEFAULT 0,
  payment_method VARCHAR(30),
  status VARCHAR(30) DEFAULT 'Completada',
  notes TEXT,
  credit_due DATE,
  cash_in DECIMAL(12,2) DEFAULT 0,
  change_out DECIMAL(12,2) DEFAULT 0,
  user_id BIGINT,
  user_name VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_date (date),
  INDEX idx_client (client_id),
  INDEX idx_status (status)
);

-- ITEMS DE VENTA
CREATE TABLE IF NOT EXISTS sale_items (
  id BIGINT PRIMARY KEY,
  sale_id BIGINT NOT NULL,
  product_id BIGINT,
  product_name VARCHAR(200),
  quantity DECIMAL(12,2) DEFAULT 1,
  price DECIMAL(12,2) DEFAULT 0,
  cost DECIMAL(12,2) DEFAULT 0,
  discount DECIMAL(5,2) DEFAULT 0,
  subtotal DECIMAL(12,2) DEFAULT 0,
  tier_name VARCHAR(50),
  price_note VARCHAR(200),
  INDEX idx_sale_id (sale_id),
  INDEX idx_product (product_id)
);

-- COMPRAS / FACTURAS DE PROVEEDOR
CREATE TABLE IF NOT EXISTS purchases (
  id BIGINT PRIMARY KEY,
  order_number VARCHAR(30),
  invoice_num VARCHAR(50),
  date DATE,
  due_date DATE,
  supplier_id BIGINT,
  supplier_name VARCHAR(200),
  items JSON,
  subtotal DECIMAL(12,2) DEFAULT 0,
  tax DECIMAL(12,2) DEFAULT 0,
  total DECIMAL(12,2) DEFAULT 0,
  paid DECIMAL(12,2) DEFAULT 0,
  payment_method VARCHAR(30),
  reference VARCHAR(100),
  status VARCHAR(30) DEFAULT 'Pendiente',
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_supplier (supplier_id),
  INDEX idx_date (date),
  INDEX idx_status (status)
);

-- ITEMS DE COMPRA
CREATE TABLE IF NOT EXISTS purchase_items (
  id BIGINT PRIMARY KEY,
  purchase_id BIGINT NOT NULL,
  product_id BIGINT,
  product_name VARCHAR(200),
  quantity DECIMAL(12,2) DEFAULT 0,
  bonus DECIMAL(12,2) DEFAULT 0,
  cost DECIMAL(12,2) DEFAULT 0,
  INDEX idx_purchase (purchase_id)
);

-- SESIONES DE CAJA
CREATE TABLE IF NOT EXISTS cash_sessions (
  id BIGINT PRIMARY KEY,
  open_date DATETIME,
  close_date DATETIME,
  opening_balance DECIMAL(12,2) DEFAULT 0,
  closing_balance DECIMAL(12,2) DEFAULT 0,
  status VARCHAR(20) DEFAULT 'open',
  user_id BIGINT,
  INDEX idx_status (status)
);

-- MOVIMIENTOS DE CAJA
CREATE TABLE IF NOT EXISTS cash_movements (
  id BIGINT PRIMARY KEY,
  session_id BIGINT,
  type VARCHAR(20),
  amount DECIMAL(12,2) DEFAULT 0,
  concept VARCHAR(200),
  date DATETIME,
  user_id BIGINT,
  INDEX idx_session (session_id),
  INDEX idx_date (date)
);

-- PAGOS DE CREDITO
CREATE TABLE IF NOT EXISTS credit_payments (
  id BIGINT PRIMARY KEY,
  sale_id BIGINT NOT NULL,
  amount DECIMAL(12,2) DEFAULT 0,
  date DATE,
  method VARCHAR(30),
  reference VARCHAR(100),
  INDEX idx_sale (sale_id)
);

-- CONFIGURACION
CREATE TABLE IF NOT EXISTS config (
  `key` VARCHAR(100) PRIMARY KEY,
  `value` TEXT
);

-- =============================================
--  DATOS INICIALES
-- =============================================

-- Usuarios por defecto
INSERT IGNORE INTO users (id, username, password, name, role, active) VALUES
(1, 'admin',   '1234', 'Administrador', 'admin',   1),
(2, 'cajero',  '1234', 'Carlos Mendez', 'cajero',  1),
(3, 'almacen', '1234', 'Ana Torres',    'almacen', 1),
(4, 'compras', '1234', 'Pedro Lara',    'compras', 1);

-- Configuracion inicial
INSERT IGNORE INTO config (`key`, `value`) VALUES
('company_name',    'AgroDistribuidora El Campo'),
('company_rtn',     '08011990001122'),
('company_address', 'Col. Las Palmas, Tegucigalpa'),
('company_phone',   '+504 2222-3333'),
('company_email',   'ventas@agrocampo.hn'),
('tax_rate',        '15'),
('max_discount',    '20'),
('credit_days',     '30'),
('invoice_prefix',  'FAC-'),
('sale_cnt',        '1000'),
('purchase_cnt',    '2000'),
('tier_names',      '["Detalle","Mayoreo","Distribuidor","Especial","Minimo"]');
