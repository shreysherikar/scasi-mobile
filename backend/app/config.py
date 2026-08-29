import os

class Settings:
    GROQ_API_KEY: str = os.environ.get("GROQ_API_KEY", "")
    GOOGLE_CLIENT_ID: str = os.environ.get("GOOGLE_CLIENT_ID", "")
    JWT_SECRET: str = os.environ.get("JWT_SECRET", "dev-secret-change-me")
    JWT_EXPIRE_DAYS: int = int(os.environ.get("JWT_EXPIRE_DAYS", "30"))
    DB_PATH: str = os.environ.get("DB_PATH", "scasi.db")
    GROQ_MODEL: str = os.environ.get("GROQ_MODEL", "openai/gpt-oss-120b")

settings = Settings()
