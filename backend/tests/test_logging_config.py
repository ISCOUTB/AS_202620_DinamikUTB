import json
import logging

from app.core.logging_config import JsonFormatter, configurar_logging


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


def test_configurar_logging_instala_formateador_json():
    logger = logging.getLogger("dinamikutb")
    handlers_originales = list(logger.handlers)
    propagate_original = logger.propagate
    nivel_original = logger.level
    try:
        logger.handlers.clear()
        configurado = configurar_logging()

        assert configurado is logger
        assert len(logger.handlers) == 1
        assert isinstance(logger.handlers[0].formatter, JsonFormatter)
        assert logger.propagate is False
    finally:
        logger.handlers = handlers_originales
        logger.propagate = propagate_original
        logger.setLevel(nivel_original)
