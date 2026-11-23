from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
FILES = [
    *DOCS.rglob("*.md"),
    ROOT / "README.md",
]

PLACEHOLDER = re.compile(
    r"\bTODO\b|(?i:lorem ipsum|arc42 template|<pendiente>|<[^>\n]*pendiente[^>\n]*>)",
)
MARKDOWN_LINK = re.compile(r"\[[^\]]+\]\(([^)#]+(?:#[^)]+)?)(?:\)|\Z)")


def check_placeholders() -> list[str]:
    errors = []
    for path in FILES:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        for line_number, line in enumerate(text.splitlines(), 1):
            if PLACEHOLDER.search(line):
                errors.append(f"{path.relative_to(ROOT)}:{line_number}: marcador o plantilla pendiente")
    return errors


def check_local_links() -> list[str]:
    errors = []
    for path in FILES:
        text = path.read_text(encoding="utf-8")
        for match in MARKDOWN_LINK.finditer(text):
            target = match.group(1)
            if "://" in target or target.startswith("mailto:"):
                continue
            target_path = target.split("#", 1)[0]
            if not target_path:
                continue
            resolved = (path.parent / target_path).resolve()
            if not resolved.exists():
                errors.append(
                    f"{path.relative_to(ROOT)}: enlace local inexistente: {target}"
                )
    return errors


def main() -> int:
    errors = check_placeholders() + check_local_links()
    if errors:
        print("\n".join(errors))
        return 1
    print("Documentacion valida: sin plantillas pendientes ni enlaces locales rotos.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
