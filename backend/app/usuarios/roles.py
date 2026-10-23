from enum import StrEnum


class Rol(StrEnum):
    ESTUDIANTE = "estudiante"
    COORDINADOR = "coordinador"
    ADMINISTRADOR = "administrador"


# Roles con acceso a los datos de cualquier estudiante y a la gestión de requisitos.
ROLES_GESTION = (Rol.COORDINADOR, Rol.ADMINISTRADOR)
