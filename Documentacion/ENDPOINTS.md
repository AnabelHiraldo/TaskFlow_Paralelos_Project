# Endpoints

Public:
POST /auth/register
POST /auth/login
GET /

Protected:
GET /users/me
GET /users
GET /users/{id}
PUT /users/{id}
DELETE /users/{id}

Tasks:
POST /tasks
GET /tasks
GET /tasks/{id}
PUT /tasks/{id}
DELETE /tasks/{id}

Files:
POST /upload
DELETE /upload/{id}

Dashboard:
GET /dashboard/profile
GET /dashboard/stats
GET /dashboard/notifications
GET /dashboard/task-summary
GET /dashboard/sequential
GET /dashboard/concurrent
