import json
import logging
import sys


class JsonFormatter(logging.Formatter):
    """Una línea JSON por registro, con campos (no cadenas sueltas)."""

    def format(self, record: logging.LogRecord) -> str:
        datos = {
            "ts": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        datos.update(getattr(record, "campos", {}) or {})
        return json.dumps(datos, ensure_ascii=False)


def configurar_logging() -> logging.Logger:
    logger = logging.getLogger("dinamikutb")
    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        handler.setFormatter(JsonFormatter())
        logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    logger.propagate = False
    return logger
