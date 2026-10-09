# TaskFlow Backend

FastAPI + PostgreSQL + SQLAlchemy + JWT + file upload + Docker.

## Local with Docker
docker compose up -d --build

API:
http://localhost:8000
Swagger:
http://localhost:8000/docs

## Demo flow
1. POST /auth/register
2. POST /auth/login
3. Copy access_token.
4. Swagger Authorize: Bearer <token>
5. Test /users, /tasks and /upload.
6. Test /dashboard/sequential and /dashboard/concurrent.

## Security
Passwords are hashed with Argon2 through pwdlib. JWT protects private endpoints.

## Concurrency
/dashboard/sequential executes four independent operations one after another.
/dashboard/concurrent executes the same operations with asyncio.gather.

The Flutter dashboard also uses Future.wait() for four independent HTTP requests and measures sequential vs concurrent execution.
