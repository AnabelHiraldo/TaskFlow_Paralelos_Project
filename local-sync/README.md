# Sincronización de usuarios con PostgreSQL local

El backend Cloud Run publica un evento mínimo (sin contraseña ni hash) al registrar un usuario. Este agente local escucha la suscripción pull de Pub/Sub y copia el registro a `cloud_registered_users` en PostgreSQL local. No abre puertos entrantes de PostgreSQL en la computadora.

## Configuración

1. Copiar `.env.example` a `.env` y cambiar `LOCAL_DATABASE_URL` para que use el usuario, la contraseña y la base de datos local reales. No subir `.env` a Git.
2. Instalar dependencias: `python -m pip install -r requirements.txt`.
3. Iniciar sesión de aplicación de Google Cloud con `gcloud auth application-default login`.
4. En Pub/Sub, conceder a la cuenta Google usada en el paso anterior el rol `Pub/Sub Subscriber` sobre `taskflow-user-sync-local`.
5. Ejecutar `python worker.py` desde esta carpeta. Mantener el proceso activo mientras se quieran replicar registros.

Los registros sincronizados se consultan con:

```sql
SELECT cloud_user_id, nombre, apellido, email, created_at
FROM cloud_registered_users
ORDER BY cloud_user_id DESC;
```

Los usuarios replicados son una copia de consulta local; el inicio de sesión y las tareas siguen usando Cloud SQL.
