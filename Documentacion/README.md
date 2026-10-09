# TaskFlow - Documentación de defensa

## Arquitectura
Flutter MVVM -> Repository -> HTTP Service -> FastAPI -> SQLAlchemy -> PostgreSQL.

## Seguridad
Login -> JWT -> Authorization: Bearer TOKEN -> protected endpoint.

Passwords are never stored as plaintext.

## CRUD
Users: create/register, list, detail, update, delete.
Tasks: create, list, detail, update, delete.

## Archivos
POST /upload validates JPG, PNG and PDF, stores the file locally and registers its metadata in `files`.
DELETE /upload/{id} removes the file and its DB record.

## Concurrencia
Sequential:
A -> B -> C -> D

Concurrent:
A, B, C, D start without waiting for the previous one.

Flutter uses `Future.wait()` for independent dashboard HTTP calls.
Backend uses `asyncio.gather()` for independent dashboard operations.

The assignment asks to implement and compare sequential vs concurrent execution, report times, explain the mechanism and discuss when parallelism is not appropriate.
