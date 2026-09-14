"""Create a source-only handoff archive; SDK, virtualenv and private data stay local."""

import hashlib
import zipfile
from pathlib import Path

from check_secrets import main as check_secrets
from check_secrets import source_files

ROOT = Path(__file__).resolve().parents[1]


def main():
    if check_secrets():
        raise SystemExit(1)
    out = ROOT / "dist"
    out.mkdir(exist_ok=True)
    archive = out / "FieldMap-G0-source.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as bundle:
        for file in source_files():
            if file.is_symlink():
                raise SystemExit("Source archive refuses symlinks.")
            bundle.write(file, Path("FieldMap-G0") / file.relative_to(ROOT))
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    (out / "SHA256SUMS").write_text(f"{digest}  {archive.name}\n")
    print(f"Created {archive.name}; SHA256 {digest}")


if __name__ == "__main__":
    main()
