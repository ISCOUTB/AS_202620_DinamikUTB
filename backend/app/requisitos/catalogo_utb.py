"""Catálogo de requisitos de grado de referencia para el programa demo.

Datos de apoyo para el estudiante, no norma. Las oficinas, portales y plazos
deben contrastarse con la UTB antes de usarse fuera del proyecto del curso.
"""

OFICINA_REGISTRO = "Registro y Control Académico"
OFICINA_COORD = "Coordinación de tu programa"

# codigo_interno -> (estado, fecha_cumplimiento, periodo, evidencia) del estudiante demo
# La fecha del demo es una fecha de ejemplo.
from datetime import date  # noqa: E402

ESTADO_DEMO = {
    "REQ-BIE-CAT": ("cumplido", date(2024, 6, 6), "2024-1", "Constancia de Bienestar Universitario"),
    "REQ-IDI-B2": ("en_proceso", None, "2026-2", ""),
    "REQ-SABERPRO": ("pendiente", None, None, ""),
    "REQ-PRACTICA": ("pendiente", None, None, ""),
    "REQ-OPCGRADO": ("pendiente", None, None, ""),
    "REQ-PYS": ("pendiente", None, None, ""),
}

REQUISITOS_UTB = [
    {
        "codigo_interno": "REQ-IDI-B2",
        "nombre": "Inglés B2",
        "descripcion": "Acreditar nivel B2 de inglés.",
        "categoria": "Idiomas",
        "semestre_recomendado": 8,
        "porcentaje_creditos_requerido": None,
        "portal_oficial": "https://www.utb.edu.co",
        "tiempo_estimado": "1 a 3 meses según la ruta",
        "guia_resumen": (
            "Se acredita con un certificado B2 de una prueba internacional o con la prueba "
            "de suficiencia del Centro de Idiomas. Aplica según tu cohorte de ingreso: "
            "confírmalo con tu coordinación."
        ),
        "pasos_guia": [
            {
                "titulo": "Elige la ruta",
                "detalle": "Opción 1: certificado B2 de una prueba internacional de competencia. "
                "Opción 2: prueba de suficiencia del Centro de Idiomas con nivel B2.",
                "oficina": "Centro de Idiomas UTB",
            },
            {
                "titulo": "Consulta costos y fechas",
                "detalle": "Escribe a idiomas@utb.edu.co para costos, fechas y proceso de registro.",
                "oficina": "Centro de Idiomas UTB",
            },
            {
                "titulo": "Presenta la prueba o radica el certificado",
                "detalle": "Entrega el certificado vigente o presenta la suficiencia en la fecha asignada.",
                "oficina": "Centro de Idiomas UTB",
            },
            {
                "titulo": "Verifica el registro",
                "detalle": "Confirma que el requisito quedó marcado en tu historial académico.",
                "oficina": OFICINA_REGISTRO,
            },
        ],
    },
    {
        "codigo_interno": "REQ-SABERPRO",
        "nombre": "Examen Saber Pro (ICFES)",
        "descripcion": "Presentar el examen de calidad de la educación superior.",
        "categoria": "Evaluacion",
        "semestre_recomendado": 8,
        "porcentaje_creditos_requerido": 75,
        "portal_oficial": "https://www.icfes.gov.co",
        "tiempo_estimado": "Según el calendario anual del ICFES",
        "guia_resumen": (
            "Necesitas haber aprobado al menos el 75 % de los créditos de tu plan para "
            "inscribirte. Presentar el examen es requisito de grado."
        ),
        "pasos_guia": [
            {
                "titulo": "Verifica tus créditos",
                "detalle": "Debes tener aprobado el 75 % de los créditos del plan. La app te dice cuántos faltan.",
                "oficina": OFICINA_REGISTRO,
            },
            {
                "titulo": "Inscríbete en las fechas del ICFES",
                "detalle": "Hazlo por el proceso que indique la Universidad para tu cohorte.",
                "oficina": OFICINA_COORD,
            },
            {
                "titulo": "Revisa el pago de derechos",
                "detalle": "Consulta en los comunicados institucionales vigentes si hay incentivo o beca para el pago.",
                "oficina": OFICINA_REGISTRO,
            },
            {
                "titulo": "Presenta el examen",
                "detalle": "Lleva tu citación y documento de identidad el día de la prueba.",
                "oficina": "ICFES",
            },
            {
                "titulo": "Guarda la constancia",
                "detalle": "Conserva el certificado de presentación: se exige al solicitar el grado.",
                "oficina": OFICINA_REGISTRO,
            },
        ],
    },
    {
        "codigo_interno": "REQ-PRACTICA",
        "nombre": "Práctica Profesional",
        "descripcion": "Completar la práctica profesional del programa.",
        "categoria": "Proyeccion",
        "semestre_recomendado": 10,
        "porcentaje_creditos_requerido": 75,
        "portal_oficial": "https://www.utb.edu.co",
        "tiempo_estimado": "Un semestre académico",
        "guia_resumen": (
            "Se habilita con el 75 % de los créditos y los prerrequisitos del curso de práctica. "
            "Puede hacerse en una organización o por la modalidad que autorice tu programa."
        ),
        "pasos_guia": [
            {
                "titulo": "Confirma que estás habilitado",
                "detalle": "75 % de créditos aprobados y prerrequisitos del curso de práctica.",
                "oficina": OFICINA_REGISTRO,
            },
            {
                "titulo": "Define la modalidad",
                "detalle": "Práctica en organización o modalidad supletiva (p. ej. seminario) según tu programa.",
                "oficina": OFICINA_COORD,
            },
            {
                "titulo": "Formaliza la vinculación",
                "detalle": "Entrega la documentación y deja listo el convenio con la organización.",
                "oficina": OFICINA_COORD,
            },
            {
                "titulo": "Matricula el curso de práctica",
                "detalle": "Se matricula como cualquier curso del plan.",
                "oficina": OFICINA_REGISTRO,
            },
            {
                "titulo": "Entrega el informe final",
                "detalle": "Radica el informe y la evaluación del supervisor en las fechas del calendario.",
                "oficina": OFICINA_COORD,
            },
        ],
    },
    {
        "codigo_interno": "REQ-OPCGRADO",
        "nombre": "Opción de Grado",
        "descripcion": "Cumplir la modalidad de grado elegida.",
        "categoria": "Academico",
        "semestre_recomendado": 10,
        "porcentaje_creditos_requerido": 80,
        "portal_oficial": "https://www.utb.edu.co",
        "tiempo_estimado": "1 a 2 semestres",
        "guia_resumen": (
            "Trabajo de grado u otra modalidad que permita el reglamento de tu facultad "
            "(Facultad de Ingeniería: Resolución 05 de 2020 del Consejo Académico). "
            "Se habilita con el 80 % de los créditos."
        ),
        "pasos_guia": [
            {
                "titulo": "Lee el reglamento de tu facultad",
                "detalle": "Define modalidades, plazos y requisitos de sustentación.",
                "oficina": OFICINA_COORD,
            },
            {
                "titulo": "Elige modalidad y director",
                "detalle": "Acuerda el tema y el director con tu coordinación.",
                "oficina": OFICINA_COORD,
            },
            {
                "titulo": "Radica la propuesta",
                "detalle": "Entrega la propuesta para aprobación en las fechas del calendario.",
                "oficina": OFICINA_COORD,
            },
            {
                "titulo": "Desarrolla y sustenta",
                "detalle": "Cumple los entregables y presenta la sustentación.",
                "oficina": OFICINA_COORD,
            },
            {
                "titulo": "Entrega la versión final",
                "detalle": "Radica el documento final y el acta de aprobación.",
                "oficina": OFICINA_REGISTRO,
            },
        ],
    },
    {
        "codigo_interno": "REQ-BIE-CAT",
        "nombre": "Bienestar Universitario y Cátedra UTB",
        "descripcion": "Actividades de Bienestar y Cátedra UTB exigidas por el programa.",
        "categoria": "Administrativo",
        "semestre_recomendado": 2,
        "porcentaje_creditos_requerido": None,
        "portal_oficial": "https://www.utb.edu.co",
        "tiempo_estimado": "Durante los primeros semestres",
        "guia_resumen": "Se cumple participando en las actividades de Bienestar y en la Cátedra UTB.",
        "pasos_guia": [
            {
                "titulo": "Inscríbete en la Cátedra UTB",
                "detalle": "Asiste a las sesiones y entrega las actividades.",
                "oficina": "Bienestar Universitario",
            },
            {
                "titulo": "Completa las actividades de Bienestar",
                "detalle": "Participa en las actividades que exige tu programa.",
                "oficina": "Bienestar Universitario",
            },
            {
                "titulo": "Solicita la constancia",
                "detalle": "Pídela al terminar para que quede registrada.",
                "oficina": "Bienestar Universitario",
            },
        ],
    },
    {
        "codigo_interno": "REQ-PYS",
        "nombre": "Paz y Salvo Integral",
        "descripcion": "Estar a paz y salvo con todas las dependencias.",
        "categoria": "Administrativo",
        "semestre_recomendado": 10,
        "porcentaje_creditos_requerido": None,
        "portal_oficial": "https://www.utb.edu.co",
        "tiempo_estimado": "5 a 10 días hábiles",
        "guia_resumen": "Es lo último que se tramita: se pide cuando ya cumpliste todo lo demás.",
        "pasos_guia": [
            {
                "titulo": "Devuelve préstamos pendientes",
                "detalle": "Libros, equipos o implementos de laboratorio.",
                "oficina": "Biblioteca y laboratorios",
            },
            {
                "titulo": "Verifica que no tengas saldos",
                "detalle": "Revisa tu estado de cuenta antes de radicar la solicitud.",
                "oficina": "Cartera",
            },
            {
                "titulo": "Radica la solicitud de paz y salvo",
                "detalle": "Hazlo cuando ya tengas los demás requisitos cumplidos.",
                "oficina": OFICINA_REGISTRO,
            },
        ],
    },
]
