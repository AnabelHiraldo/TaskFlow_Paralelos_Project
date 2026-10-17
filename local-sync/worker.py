"""Replica altas de Cloud SQL a PostgreSQL local usando Pub/Sub pull."""
import json
import logging
import os

import psycopg
from google.cloud import pubsub_v1
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger("taskflow-local-sync")

PROJECT_ID = os.environ["GCP_PROJECT_ID"]
SUBSCRIPTION_ID = os.getenv("PUBSUB_SUBSCRIPTION", "taskflow-user-sync-local")
DATABASE_URL = os.environ["LOCAL_DATABASE_URL"]


def ensure_table() -> None:
    with psycopg.connect(DATABASE_URL) as conn, conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS cloud_registered_users (
                cloud_user_id BIGINT PRIMARY KEY,
                nombre VARCHAR(100) NOT NULL,
                apellido VARCHAR(100) NOT NULL,
                email VARCHAR(255) NOT NULL UNIQUE,
                created_at TIMESTAMPTZ NOT NULL,
                is_active BOOLEAN NOT NULL DEFAULT TRUE,
                synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            )
        """)


def receive_message(message: pubsub_v1.subscriber.message.Message) -> None:
    try:
        user = json.loads(message.data.decode("utf-8"))
        with psycopg.connect(DATABASE_URL) as conn, conn.cursor() as cur:
            cur.execute("""
                INSERT INTO cloud_registered_users
                    (cloud_user_id, nombre, apellido, email, created_at, is_active)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT (cloud_user_id) DO UPDATE SET
                    nombre = EXCLUDED.nombre,
                    apellido = EXCLUDED.apellido,
                    email = EXCLUDED.email,
                    is_active = EXCLUDED.is_active,
                    synced_at = NOW()
            """, (
                user["id"], user["nombre"], user["apellido"], user["email"],
                user["created_at"], user.get("is_active", True),
            ))
        message.ack()
        logger.info("Usuario cloud id=%s sincronizado a PostgreSQL local", user["id"])
    except Exception:
        logger.exception("Error sincronizando mensaje Pub/Sub; se reintentará")
        message.nack()


def main() -> None:
    ensure_table()
    subscriber = pubsub_v1.SubscriberClient()
    path = subscriber.subscription_path(PROJECT_ID, SUBSCRIPTION_ID)
    logger.info("Escuchando %s", path)
    future = subscriber.subscribe(path, callback=receive_message)
    try:
        future.result()
    except KeyboardInterrupt:
        future.cancel()
        future.result()
    finally:
        subscriber.close()


if __name__ == "__main__":
    main()
