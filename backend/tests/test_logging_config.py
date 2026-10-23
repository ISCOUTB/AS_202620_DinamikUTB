import json
import logging

from app.core.logging_config import JsonFormatter


def test_json_formatter_incluye_datos_del_registro_y_campos_adicionales():
    registro = logging.LogRecord(
        name="dinamikutb",
        level=logging.INFO,
        pathname="main.py",
        lineno=12,
        msg="http_request",
        args=(),
        exc_info=None,
    )
    registro.campos = {"status": 200}

    datos = json.loads(JsonFormatter().format(registro))

    assert datos["logger"] == "dinamikutb"
    assert datos["level"] == "INFO"
    assert datos["message"] == "http_request"
    assert datos["status"] == 200
