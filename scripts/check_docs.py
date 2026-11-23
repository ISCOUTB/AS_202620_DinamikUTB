"""Valida enlaces Markdown y reglas mínimas de trazabilidad del repositorio.

Uso:
    python scripts/check_docs.py          # solo verifica (exit 1 si falla)
    python scripts/check_docs.py --fix    # reescribe anclas mal formadas
"""

from __future__ import annotations

import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED_DIRS = {".git", ".venv", ".pytest_cache", "__pycache__", "build", "node_modules"}
LINK_RE = re.compile(r"(?P<open>\[[^\]]*\]\()(?P<url>[^)\s]+)(?P<close>\))")
HEADING_RE = re.compile(r"^#{1,6}\s+(.+?)\s*$", re.MULTILINE)
DECLARE_RE = re.compile(
    r"\b(?:Person|Person_Ext|System|System_Ext|Container|Container_Ext|"
    r"ContainerDb|ContainerDb_Ext|Component|ComponentDb)\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*,"
)

# Aliases citados por docs/evidencia-s13.md y por los ADR en el diagrama C4.
C4_ALIASES = {
    "estudiante",
    "coordinador",
    "administrador",
    "token_store",
    "proxy",
    "web_lab",
    "backend_lab",
    "database_lab",
    "database_local",
    "logs",
    "smtp",
}


def slug(text: str) -> str:
    """Slug compatible con GitHub para un encabezado Markdown."""
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = text.strip().lower()
    text = re.sub(r"[^\w\s-]", "", text, flags=re.UNICODE)
    # GitHub convierte cada espacio en un guion; no colapsa los espacios
    # que quedan al eliminar una raya (—), de ahí los slugs con "--".
    return text.strip().replace(" ", "-")


def sin_acentos(text: str) -> str:
    plano = "".join(c for c in unicodedata.normalize("NFKD", text) if not unicodedata.combining(c))
    return re.sub(r"-{2,}", "-", plano.lower())


def archivos_md() -> list[Path]:
    return [
        p
        for p in ROOT.rglob("*.md")
        if not any(parte in EXCLUDED_DIRS for parte in p.parts)
    ]


def encabezados(path: Path) -> set[str]:
    return {slug(m.group(1)) for m in HEADING_RE.finditer(path.read_text(encoding="utf-8"))}


def revisar_enlaces(fix: bool) -> list[str]:
    errores: list[str] = []
    cache: dict[Path, set[str]] = {}

    for archivo in archivos_md():
        original = archivo.read_text(encoding="utf-8")
        cambios: list[str] = []

        def reemplazar(match: re.Match[str]) -> str:
            url = match.group("url")
            if url.startswith(("http://", "https://", "mailto:", "data:", "#")):
                return match.group(0)

            destino, _, ancla = url.partition("#")
            destino = destino.strip().rstrip("/")
            objetivo = (archivo.parent / destino).resolve() if destino else archivo.resolve()

            if not objetivo.exists():
                errores.append(f"{archivo.relative_to(ROOT)}: archivo no existe: {destino}")
                return match.group(0)

            if not ancla or objetivo.suffix.lower() != ".md":
                return match.group(0)

            if objetivo not in cache:
                cache[objetivo] = encabezados(objetivo)
            slugs = cache[objetivo]

            if ancla in slugs:
                return match.group(0)

            candidatos = [s for s in slugs if sin_acentos(s) == sin_acentos(ancla)]
            if len(candidatos) == 1:
                corregido = f"{destino}#{candidatos[0]}" if destino else f"#{candidatos[0]}"
                cambios.append(f"{ancla} -> {candidatos[0]}")
                return f"{match.group('open')}{corregido}{match.group('close')}"

            errores.append(
                f"{archivo.relative_to(ROOT)}: ancla no encontrada ({ancla}) en {destino or 'este archivo'}"
            )
            return match.group(0)

        actualizado = LINK_RE.sub(reemplazar, original)
        if fix and actualizado != original:
            archivo.write_text(actualizado, encoding="utf-8")
            for cambio in cambios:
                print(f"corregido {archivo.relative_to(ROOT)}: {cambio}")

    return errores


def revisar_c4() -> list[str]:
    errores: list[str] = []
    puml = ROOT / "docs" / "c4" / "contenedores.puml"
    if not puml.exists():
        return ["falta docs/c4/contenedores.puml"]

    texto = puml.read_text(encoding="utf-8")
    declarados = set(DECLARE_RE.findall(texto))
    for alias in sorted(C4_ALIASES - declarados):
        errores.append(f"C4: el alias `{alias}` citado en evidencias no está declarado en contenedores.puml")
    if "GitHub Pages" not in texto:
        errores.append("C4: el frontend debe declararse en GitHub Pages (ADR-0006/0012)")
    if "footer" not in texto:
        errores.append("C4: falta el pie con la integración síncrona (ADR-0004)")
    if not (ROOT / "docs" / "c4" / "contenedores.png").exists():
        errores.append("C4: falta contenedores.png")
    return errores


def main() -> int:
    fix = "--fix" in sys.argv[1:]
    errores = revisar_enlaces(fix) + revisar_c4()
    if errores:
        print(f"FALLÓ: {len(errores)} problema(s)")
        for error in errores:
            print(f"  - {error}")
        return 1
    print("OK: enlaces Markdown y trazabilidad C4 verificados")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
