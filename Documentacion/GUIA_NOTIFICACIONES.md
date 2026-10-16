# Guía del flujo de correo de TaskFlow

## Qué pasa al enviar un correo

1. En **Mobile**, la pantalla `NotificationsView` valida los campos y llama a `ApiService`.
2. El backend valida los datos y el JWT. No intenta conectarse al servidor de correo: publica un mensaje JSON en el tema Pub/Sub `taskflow-notifications`.
3. Pub/Sub entrega el mensaje a `POST /pubsub` en `notification-cloud-run` mediante una suscripción push autenticada con OIDC.
4. La segunda Cloud Run lee el mensaje, conecta por SMTP con TLS y confirma a Pub/Sub cuando el envío termina.
5. Si falla SMTP, devuelve un error para que Pub/Sub intente entregar el mensaje de nuevo. El log de ambas Cloud Run aparece en Cloud Logging.

La respuesta `202` y el texto **Mensaje enviado correctamente.** significan que Pub/Sub aceptó el mensaje; el envío del correo ocurre después. La confirmación final se comprueba en los logs y en el buzón destino.

## Dónde está cada pieza

| Ruta | Para qué sirve |
| --- | --- |
| `Mobile/lib/views/notifications/notifications_view.dart` | Formulario y estados de envío en Flutter. |
| `Mobile/lib/views/dashboard/dashboard_view.dart` | Acceso a la nueva pantalla desde el inicio. |
| `Mobile/lib/services/api_service.dart` | Llamada HTTP con el JWT guardado por la app. |
| `Backend/app/routers/notifications.py` | Validación, autorización y publicación en Pub/Sub. |
| `Backend/app/config.py` | Configuración del proyecto y nombre del tema. |
| `Notification/app/main.py` | Recibe la envoltura Pub/Sub, manda el correo y escribe logs. |
| `Notification/Dockerfile` | Construye la imagen del servicio de notificaciones. |
| `terraform/main.tf` | Tema, suscripción push, cuentas IAM, secretos y Cloud Run nueva. |
| `terraform/variables.tf` | Valores configurables por proyecto y SMTP. |
| `terraform/outputs.tf` | URL del servicio, tema y suscripción para consulta. |
| `.github/workflows/deploy.yml` | Construye ambas imágenes, valida Terraform, crea la infraestructura y publica el backend. |
| `terraform/api-gateway.yaml` | Añade `POST /notifications/send` al gateway que consume la app. |

## Preparación en Google Cloud

La cuenta de despliegue de GitHub debe autenticarse mediante el Workload Identity Federation que ya usa el workflow. Necesita permisos para Artifact Registry, Cloud Run, Pub/Sub, Secret Manager, Logging, IAM y los recursos existentes de Cloud SQL y Storage que ya administra Terraform. También debe poder actuar como las cuentas runtime de Cloud Run.

El backend remoto de Terraform necesita un bucket de Cloud Storage creado una sola vez antes de que corra GitHub Actions. Usa acceso uniforme, acceso público bloqueado y versionado de objetos. Guarda el nombre como secreto `TF_STATE_BUCKET` en GitHub Actions. El bucket del estado contiene datos sensibles de Terraform: limita quién puede leerlo y no lo compartas.

Si los recursos base de TaskFlow ya existen en el proyecto, importa esos recursos existentes al estado remoto antes del primer `apply`. Este repositorio desplegaba el backend con `gcloud`, y el workflow anterior no configuraba estado Terraform; por eso un estado vacío podría intentar recrear Artifact Registry, Cloud SQL, secretos o el bucket y terminar con conflictos. No borres esos recursos para resolverlos: primero asócialos al estado con `terraform import`.

## Secretos para GitHub Actions

Crea estos GitHub Actions secrets antes de ejecutar el workflow:

| Secreto | Valor |
| --- | --- |
| `TF_STATE_BUCKET` | Bucket ya creado para el estado remoto de Terraform. |
| `TF_DB_PASSWORD` | Contraseña del usuario PostgreSQL. |
| `TF_JWT_SECRET` | Clave privada con la que se firman los JWT. |
| `SMTP_HOST` | Host SMTP permitido por el proveedor del correo. |
| `SMTP_PORT` | `587` para STARTTLS o `465` para SSL. |
| `SMTP_USERNAME` | Usuario de la cuenta SMTP. |
| `SMTP_PASSWORD` | Contraseña SMTP o contraseña de aplicación. |
| `SMTP_FROM` | Dirección remitente verificada en el proveedor. |

El estado Terraform almacena el valor de los secretos que Terraform administra, aunque la consola los marque como sensibles y no los imprima en el plan. Por eso el bucket y sus permisos son importantes. `terraform.tfvars` es local e ignorado por Git; parte de `terraform.tfvars.example` si haces un despliegue manual.

## Activar el endpoint en API Gateway

El archivo `terraform/api-gateway.yaml` declara la ruta. El workflow crea una configuración nueva para la API `taskflow-api` y la vincula al gateway `taskflow-gateway` después de desplegar el backend. Estos nombres corresponden a los recursos ya configurados para este proyecto.

## Evidencia que debes capturar después del despliegue

El pipeline construye la infraestructura al ejecutar Terraform en `main`. En Google Cloud Console captura:

1. **Pub/Sub → Temas**: `taskflow-notifications`.
2. **Pub/Sub → Suscripciones**: `taskflow-notifications-to-cloud-run` con entrega push.
3. **Cloud Run**: el backend `taskflow-api` y `notification-cloud-run`.
4. **Cloud Logging → Explorador de logs**: filtra el recurso Cloud Run por cada servicio; busca `Notificación publicada`, `Correo enviado correctamente` o `Falló el envío del correo`.
5. **Mobile**: abre **Enviar correo**, completa destinatario, asunto y mensaje, y captura el resultado.
6. **Buzón destinatario**: captura el mensaje recibido. Un `202` confirma que el mensaje entró en la cola; no garantiza por sí solo que SMTP haya terminado.

Para probar desde Swagger, inicia sesión en `/auth/login`, copia `access_token`, pulsa **Authorize** y envía el cuerpo requerido a `POST /notifications/send`.
