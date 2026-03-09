"""
AgroPoint Pro - Backend Flask + MySQL
Convierte el sistema frontend-only a una aplicación web completa con base de datos.
"""

from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import pymysql
import pymysql.cursors
import json
import os
from datetime import datetime, date
from decimal import Decimal
from dotenv import load_dotenv
import logging

load_dotenv()

# ─── APP ───────────────────────────────────────────────────────────────────────
app = Flask(__name__, static_folder="static")
CORS(app)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ─── DB CONFIG ─────────────────────────────────────────────────────────────────
DB_CONFIG = {
    "host":     os.getenv("DB_HOST",     "localhost"),
    "port":     int(os.getenv("DB_PORT", "3306")),
    "user":     os.getenv("DB_USER",     "agropoint"),
    "password": os.getenv("DB_PASSWORD", "agropoint123"),
    "database": os.getenv("DB_NAME",     "agropoint"),
    "charset":  "utf8mb4",
    "cursorclass": pymysql.cursors.DictCursor,
    "autocommit": False,
}

# Stores válidos y sus tablas
STORES = [
    "products", "clients", "suppliers", "users",
    "sales", "sale_items", "purchases", "purchase_items",
    "cash_movements", "cash_sessions", "credit_payments",
]


def get_db():
    return pymysql.connect(**DB_CONFIG)


def serialize(obj):
    """Convierte tipos MySQL a JSON-serializable."""
    if obj is None:
        return None
    if isinstance(obj, dict):
        result = {}
        for k, v in obj.items():
            result[k] = serialize(v)
        return result
    if isinstance(obj, list):
        return [serialize(i) for i in obj]
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    if isinstance(obj, Decimal):
        return float(obj)
    if isinstance(obj, (bytes, bytearray)):
        try:
            s = obj.decode("utf-8")
            if s.startswith(("[", "{")):
                return json.loads(s)
            return s
        except Exception:
            return str(obj)
    if isinstance(obj, str):
        stripped = obj.strip()
        if stripped.startswith(("[", "{")):
            try:
                return json.loads(stripped)
            except Exception:
                pass
        return obj
    return obj


def prepare_val(v):
    """Convierte listas/dicts a JSON string para almacenar en MySQL."""
    if isinstance(v, (list, dict)):
        return json.dumps(v, ensure_ascii=False)
    if isinstance(v, bool):
        return 1 if v else 0
    return v


# ─── STATIC ────────────────────────────────────────────────────────────────────
@app.route("/")
def index():
    return send_from_directory("static", "index.html")


@app.route("/static/<path:filename>")
def static_files(filename):
    return send_from_directory("static", filename)


# ─── AUTH ──────────────────────────────────────────────────────────────────────
@app.route("/api/login", methods=["POST"])
def login():
    data = request.json or {}
    username = data.get("username", "").strip()
    password = data.get("password", "")

    conn = get_db()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, username, name, role, active FROM users "
                "WHERE username=%s AND password=%s AND active=1",
                (username, password),
            )
            user = cur.fetchone()
        if user:
            return jsonify(serialize(user))
        return jsonify({"error": "Usuario o contraseña incorrectos"}), 401
    except Exception as e:
        logger.error("Login error: %s", e)
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()


# ─── GENERIC CRUD ──────────────────────────────────────────────────────────────
@app.route("/api/<store>", methods=["GET"])
def get_all(store):
    if store not in STORES:
        return jsonify({"error": "Store inválido"}), 400
    conn = get_db()
    try:
        with conn.cursor() as cur:
            cur.execute(f"SELECT * FROM `{store}`")
            rows = cur.fetchall()
        return jsonify(serialize(rows))
    except Exception as e:
        logger.error("getAll %s: %s", store, e)
        return jsonify([])
    finally:
        conn.close()


@app.route("/api/<store>", methods=["POST"])
def put_item(store):
    if store not in STORES:
        return jsonify({"error": "Store inválido"}), 400

    item = request.json
    if not item:
        return jsonify({"error": "Sin datos"}), 400

    # Preparar valores
    data = {k: prepare_val(v) for k, v in item.items()}

    conn = get_db()
    try:
        with conn.cursor() as cur:
            item_id = data.get("id")

            if item_id:
                # ¿Existe?
                cur.execute(f"SELECT id FROM `{store}` WHERE id=%s", (item_id,))
                exists = cur.fetchone()

                if exists:
                    # UPDATE
                    fields = [k for k in data if k != "id"]
                    if fields:
                        sets = ", ".join(f"`{k}`=%s" for k in fields)
                        vals = [data[k] for k in fields] + [item_id]
                        cur.execute(f"UPDATE `{store}` SET {sets} WHERE id=%s", vals)
                else:
                    # INSERT con id específico
                    cols = ", ".join(f"`{k}`" for k in data)
                    placeholders = ", ".join(["%s"] * len(data))
                    cur.execute(
                        f"INSERT INTO `{store}` ({cols}) VALUES ({placeholders})",
                        list(data.values()),
                    )
            else:
                # INSERT sin id (auto-increment o no necesario)
                clean = {k: v for k, v in data.items() if k != "id"}
                if clean:
                    cols = ", ".join(f"`{k}`" for k in clean)
                    placeholders = ", ".join(["%s"] * len(clean))
                    cur.execute(
                        f"INSERT INTO `{store}` ({cols}) VALUES ({placeholders})",
                        list(clean.values()),
                    )
                    item_id = cur.lastrowid

        conn.commit()
        return jsonify({"id": item_id, "success": True})

    except Exception as e:
        conn.rollback()
        logger.error("putItem %s: %s | data=%s", store, e, data)
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()


@app.route("/api/<store>/<item_id>", methods=["DELETE"])
def del_item(store, item_id):
    if store not in STORES:
        return jsonify({"error": "Store inválido"}), 400
    conn = get_db()
    try:
        with conn.cursor() as cur:
            cur.execute(f"DELETE FROM `{store}` WHERE id=%s", (item_id,))
        conn.commit()
        return jsonify({"success": True})
    except Exception as e:
        conn.rollback()
        logger.error("delItem %s/%s: %s", store, item_id, e)
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()


# ─── CONFIG ────────────────────────────────────────────────────────────────────
@app.route("/api/config/<key>", methods=["GET"])
def get_config(key):
    conn = get_db()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT `key`, `value` FROM config WHERE `key`=%s", (key,))
            row = cur.fetchone()
        if row:
            # Intentar parsear JSON
            val = row["value"]
            try:
                if val and val.strip().startswith(("[", "{")):
                    val = json.loads(val)
            except Exception:
                pass
            return jsonify({"key": row["key"], "value": val})
        return jsonify({"key": key, "value": None})
    except Exception as e:
        logger.error("getCfg %s: %s", key, e)
        return jsonify({"key": key, "value": None})
    finally:
        conn.close()


@app.route("/api/config/<key>", methods=["PUT", "POST"])
def set_config(key):
    data = request.json or {}
    value = data.get("value")
    if isinstance(value, (list, dict)):
        value = json.dumps(value, ensure_ascii=False)
    elif value is not None:
        value = str(value)

    conn = get_db()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO config (`key`, `value`) VALUES (%s, %s) "
                "ON DUPLICATE KEY UPDATE `value`=%s",
                (key, value, value),
            )
        conn.commit()
        return jsonify({"success": True})
    except Exception as e:
        conn.rollback()
        logger.error("setCfg %s: %s", key, e)
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()


# ─── ENDPOINTS EXTRA ───────────────────────────────────────────────────────────
@app.route("/api/config", methods=["GET"])
def get_all_config():
    """Devuelve toda la configuración de una vez."""
    conn = get_db()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT `key`, `value` FROM config")
            rows = cur.fetchall()
        result = {}
        for row in rows:
            val = row["value"]
            try:
                if val and val.strip().startswith(("[", "{")):
                    val = json.loads(val)
            except Exception:
                pass
            result[row["key"]] = val
        return jsonify(result)
    except Exception as e:
        return jsonify({})
    finally:
        conn.close()


@app.route("/api/dashboard", methods=["GET"])
def dashboard_summary():
    """Resumen rápido para el dashboard."""
    conn = get_db()
    try:
        today_str = datetime.now().strftime("%Y-%m-%d")
        month_start = datetime.now().strftime("%Y-%m-01")

        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) as c, COALESCE(SUM(total),0) as s FROM sales WHERE DATE(date)=%s", (today_str,))
            today_sales = cur.fetchone()

            cur.execute("SELECT COUNT(*) as c, COALESCE(SUM(total),0) as s FROM sales WHERE date>=%s", (month_start,))
            month_sales = cur.fetchone()

            cur.execute("SELECT COUNT(*) as c FROM products WHERE active=1 AND stock<=min_stock")
            low_stock = cur.fetchone()

            cur.execute("SELECT COALESCE(SUM(balance),0) as s FROM clients WHERE balance>0")
            credit_total = cur.fetchone()

        return jsonify({
            "today_sales_count": today_sales["c"],
            "today_sales_total": float(today_sales["s"]),
            "month_sales_count": month_sales["c"],
            "month_sales_total": float(month_sales["s"]),
            "low_stock_count": low_stock["c"],
            "credit_total": float(credit_total["s"]),
        })
    except Exception as e:
        logger.error("Dashboard: %s", e)
        return jsonify({})
    finally:
        conn.close()


@app.route("/api/health", methods=["GET"])
def health():
    try:
        conn = get_db()
        conn.ping()
        conn.close()
        return jsonify({"status": "ok", "db": "connected"})
    except Exception as e:
        return jsonify({"status": "error", "db": str(e)}), 500


# ─── RUN ───────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    debug = os.getenv("FLASK_DEBUG", "false").lower() == "true"
    app.run(host="0.0.0.0", port=port, debug=debug)
