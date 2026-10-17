from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    database_url: str = "postgresql+psycopg://taskflow_user:taskflow_password@localhost:5432/taskflow"
    jwt_secret_key: str = "change-this-secret"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    gcp_project_id: str | None = None
    notification_topic: str = "taskflow-notifications"
    user_sync_topic: str = "taskflow-user-sync"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

settings = Settings()
