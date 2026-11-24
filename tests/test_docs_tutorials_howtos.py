"""Executable validation tests for Rundeck Diátaxis EN/FR docs, Mermaid diagrams, YAML, ACLs, Compose, and scripts."""

from __future__ import annotations

import os
import py_compile
import re
import shutil
import subprocess
import sys
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
DOCS_DIR = REPO_ROOT / "docs"
DOCS_FR_DIR = DOCS_DIR / "fr"

LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)\n]+)\)")
FENCE_RE = re.compile(r"^(?P<indent>[ \t]*)(?P<ticks>`{3,}|~{3,})(?P<info>.*)$")
BOX_CHAR_RE = re.compile(r"[\u2500-\u257f▼▲◄►]")
ASSET_REF_RE = re.compile(
    r"((?:docker|ansible|templates|scripts|aclpolicy|ressources|jobs|propertyfile)/"
    r"[a-zA-Z0-9_./-]+\.(?:ya?ml|sh|py|html|md|example))"
)

FRENCH_MARKERS = re.compile(
    r"\b(?:procédure|tutoriel|démarrage|prérequis|vérification|"
    r"retour\s+arrière|utilisation|tableau\s+de\s+bord|pare-feu)\b",
    re.IGNORECASE,
)
ENGLISH_ONLY_HEADINGS = re.compile(
    r"(?m)^#{1,4}\s+(?:Prerequisites|Overview|Rollback|Verification|Features|Usage)\b"
)
ENGLISH_HOWTO_BANNED = re.compile(
    r"(?:;|should\b|would\b|may\b|might\b|shall\b|"
    r"\b(?:don't|doesn't|isn't|aren't|won't|can't|let's)\b)",
    re.IGNORECASE,
)
FRENCH_HOWTO_BANNED = re.compile(r"(?:;|\b(?:devrait|devraient|pourrait|pourraient)\b)", re.IGNORECASE)


def _iter_markdown() -> list[Path]:
    """Return all Markdown files in the repository excluding .git."""
    return sorted(p for p in REPO_ROOT.rglob("*.md") if ".git/" not in p.as_posix())


def _strip_fenced_blocks(text: str) -> list[tuple[int, str]]:
    """Return (lineno, line) pairs outside fenced code blocks."""
    out: list[tuple[int, str]] = []
    fence_char: str | None = None
    fence_len = 0
    for lineno, raw_line in enumerate(text.splitlines(), start=1):
        if fence_char is not None:
            if re.match(rf"^\s*{re.escape(fence_char)}{{{fence_len},}}\s*$", raw_line):
                fence_char = None
                fence_len = 0
            continue
        match = FENCE_RE.match(raw_line)
        if match:
            ticks = match.group("ticks")
            fence_char = ticks[0]
            fence_len = len(ticks)
            continue
        out.append((lineno, raw_line))
    return out


def _extract_fenced_blocks(text: str) -> list[dict[str, object]]:
    """Extract all fenced code blocks with line number, indent, info string, and body."""
    blocks: list[dict[str, object]] = []
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        match = FENCE_RE.match(lines[i])
        if not match:
            i += 1
            continue
        indent = match.group("indent")
        ticks = match.group("ticks")
        info = match.group("info").strip()
        fence_char = ticks[0]
        fence_len = len(ticks)
        start_line = i + 1
        body: list[str] = []
        i += 1
        while i < len(lines):
            if re.match(rf"^\s*{re.escape(fence_char)}{{{fence_len},}}\s*$", lines[i]):
                break
            body.append(lines[i])
            i += 1
        blocks.append({"line": start_line, "indent": indent, "info": info, "code": "\n".join(body)})
        i += 1
    return blocks


class TestDocsTutorialsAndHowTos(unittest.TestCase):
    """Validate Diátaxis EN/FR suites, FR/EN isolation, Mermaid blocks, YAML, Compose, and scripts."""

    def test_diataxis_en_and_fr_structure_and_links(self) -> None:
        required = [
            DOCS_DIR / "index.md",
            DOCS_DIR / "01-tutorials" / "index.md",
            DOCS_DIR / "01-tutorials" / "01-docker-rundeck-quickstart.md",
            DOCS_DIR / "01-tutorials" / "02-ansible-acl-and-minio-lab.md",
            DOCS_DIR / "02-how-to-guides" / "index.md",
            DOCS_DIR / "02-how-to-guides" / "deploy-docker-and-swarm.md",
            DOCS_DIR / "02-how-to-guides" / "configure-acl-and-minio-job.md",
            DOCS_DIR / "03-reference" / "index.md",
            DOCS_DIR / "03-reference" / "compose-ansible-acl-and-scripts.md",
            DOCS_DIR / "04-explanation" / "index.md",
            DOCS_DIR / "04-explanation" / "architecture-acl-and-deployment-models.md",
            DOCS_FR_DIR / "index.md",
            DOCS_FR_DIR / "01-tutoriels" / "index.md",
            DOCS_FR_DIR / "01-tutoriels" / "01-demarrage-docker-rundeck.md",
            DOCS_FR_DIR / "02-guides-pratiques" / "index.md",
            DOCS_FR_DIR / "02-guides-pratiques" / "deployer-docker-et-swarm.md",
            DOCS_FR_DIR / "02-guides-pratiques" / "configurer-acl-et-job-minio.md",
            DOCS_FR_DIR / "03-reference" / "index.md",
            DOCS_FR_DIR / "03-reference" / "ports-ansible-acl-et-scripts.md",
            DOCS_FR_DIR / "04-explications" / "index.md",
            DOCS_FR_DIR / "04-explications" / "architecture-acl-et-modes-deploiement.md",
            REPO_ROOT / "README.md",
            REPO_ROOT / "README.fr.md",
            REPO_ROOT / "propertyfile" / "README.md",
            REPO_ROOT / "propertyfile" / "README.en.md",
        ]
        for path in required:
            self.assertTrue(path.is_file(), f"Missing document: {path}")

        repo_resolved = REPO_ROOT.resolve()
        for md_file in _iter_markdown():
            text = md_file.read_text(encoding="utf-8")
            for lineno, line in _strip_fenced_blocks(text):
                for match in LINK_RE.finditer(line):
                    raw = match.group(1).strip()
                    target = raw.split()[0] if not raw.startswith("<") else raw[1 : raw.find(">")]
                    target = target.split("#", 1)[0].split("?", 1)[0].strip()
                    if not target or target.startswith(("http://", "https://", "mailto:", "data:")):
                        continue
                    self.assertFalse(target.startswith("file://"), f"Disallowed file:// URI in {md_file}:{lineno}")
                    resolved = (md_file.parent / target).resolve()
                    self.assertTrue(
                        resolved.exists() and str(resolved).startswith(str(repo_resolved)),
                        f"Broken relative link at {md_file}:{lineno} -> {target}",
                    )

        for guide in sorted((DOCS_DIR / "02-how-to-guides").glob("*.md")):
            if guide.name == "index.md":
                continue
            text = guide.read_text(encoding="utf-8")
            self.assertRegex(text, r"(?m)^##\s+Prerequisites\b")
            self.assertRegex(text, r"(?m)^##\s+Verification\b")
            self.assertRegex(text, r"(?m)^##\s+Rollback\b")
            prose = "\n".join(line for _, line in _strip_fenced_blocks(text))
            self.assertIsNone(ENGLISH_HOWTO_BANNED.search(prose), f"STE rule violation in {guide}")

        for guide in sorted((DOCS_FR_DIR / "02-guides-pratiques").glob("*.md")):
            if guide.name == "index.md":
                continue
            text = guide.read_text(encoding="utf-8")
            self.assertRegex(text, r"(?m)^##\s+Prérequis\b")
            self.assertRegex(text, r"(?m)^##\s+Vérification\b")
            self.assertRegex(text, r"(?m)^##\s+Retour\s+arrière\b")
            prose = "\n".join(line for _, line in _strip_fenced_blocks(text))
            self.assertIsNone(FRENCH_HOWTO_BANNED.search(prose), f"STF rule violation in {guide}")

        skills_root = Path.home() / ".gemini" / "config" / "skills" / "diataxis-docs" / "scripts"
        en_check = skills_root / "diataxis_check.py"
        if en_check.is_file():
            res = subprocess.run(
                [sys.executable, str(en_check), str(DOCS_DIR), "--strict", "--check-ste", "--lang", "en"],
                capture_output=True,
                text=True,
                timeout=60,
            )
            self.assertEqual(res.returncode, 0, f"diataxis_check.py failed:\n{res.stdout}\n{res.stderr}")

        fr_check = skills_root / "diataxis_check_fr.py"
        if fr_check.is_file():
            res = subprocess.run(
                [sys.executable, str(fr_check), str(DOCS_FR_DIR), "--strict", "--check-stf"],
                capture_output=True,
                text=True,
                timeout=60,
            )
            self.assertEqual(res.returncode, 0, f"diataxis_check_fr.py failed:\n{res.stdout}\n{res.stderr}")

    def test_fr_en_separation(self) -> None:
        readme_en = (REPO_ROOT / "README.md").read_text(encoding="utf-8")
        readme_fr = (REPO_ROOT / "README.fr.md").read_text(encoding="utf-8")
        self.assertIn("[Français](README.fr.md)", readme_en)
        self.assertIn("[English](README.md)", readme_fr)
        self.assertIsNone(FRENCH_MARKERS.search(readme_en), "French markers leaked into README.md")
        self.assertIsNone(ENGLISH_ONLY_HEADINGS.search(readme_fr), "English headings leaked into README.fr.md")

        prop_fr = (REPO_ROOT / "propertyfile" / "README.md").read_text(encoding="utf-8")
        prop_en = (REPO_ROOT / "propertyfile" / "README.en.md").read_text(encoding="utf-8")
        self.assertIsNone(ENGLISH_ONLY_HEADINGS.search(prop_fr), "English headings leaked into propertyfile/README.md")
        self.assertIsNone(FRENCH_MARKERS.search(prop_en), "French markers leaked into propertyfile/README.en.md")
        self.assertIn("BCRYPT", prop_fr)
        self.assertIn("BCRYPT", prop_en)

        en_quadrants = ("01-tutorials", "02-how-to-guides", "03-reference", "04-explanation")
        for quadrant in en_quadrants:
            for md_file in sorted((DOCS_DIR / quadrant).rglob("*.md")):
                self.assertIsNone(
                    FRENCH_MARKERS.search(md_file.read_text(encoding="utf-8")),
                    f"French markers leaked into EN doc {md_file}",
                )

        for md_file in sorted(DOCS_FR_DIR.rglob("*.md")):
            self.assertIsNone(
                ENGLISH_ONLY_HEADINGS.search(md_file.read_text(encoding="utf-8")),
                f"English headings leaked into FR doc {md_file}",
            )

    def test_mermaid_and_zero_ascii_diagrams(self) -> None:
        mermaid_count = 0
        for md_file in _iter_markdown():
            text = md_file.read_text(encoding="utf-8")
            for lineno, line in _strip_fenced_blocks(text):
                self.assertIsNone(BOX_CHAR_RE.search(line), f"ASCII box/arrow char in prose {md_file}:{lineno}")
            for block in _extract_fenced_blocks(text):
                code = str(block["code"])
                info = str(block["info"]).lower()
                indent = str(block["indent"])
                lineno = int(block["line"])
                self.assertIsNone(BOX_CHAR_RE.search(code), f"ASCII box/arrow diagram in {md_file}:{lineno}")
                if info.startswith("mermaid"):
                    self.assertEqual(indent, "", f"Indented mermaid fence in {md_file}:{lineno}")
                    self.assertRegex(
                        code.lstrip(),
                        r"^(?:graph|flowchart|sequenceDiagram|stateDiagram|classDiagram|erDiagram)\b",
                    )
                    mermaid_count += 1
                elif re.match(r"^(?:graph|flowchart)\s+(?:TD|LR|TB|RL)\b|^sequenceDiagram\b", code.lstrip()):
                    self.fail(f"Untagged Mermaid block at {md_file}:{lineno}")

        self.assertGreaterEqual(mermaid_count, 9)

        acl_guide = (DOCS_DIR / "droits_comptes_rundeck.md").read_text(encoding="utf-8")
        self.assertNotIn("# <--", acl_guide)
        self.assertNotIn("<!-- end list -->", acl_guide)

    def test_yaml_acl_ansible_templates_compose_python_and_shell_scripts(self) -> None:
        for md_file in [
            REPO_ROOT / "README.md",
            REPO_ROOT / "README.fr.md",
            *sorted(DOCS_FR_DIR.rglob("*.md")),
            *(
                p
                for q in ("01-tutorials", "02-how-to-guides", "03-reference", "04-explanation")
                for p in sorted((DOCS_DIR / q).rglob("*.md"))
            ),
        ]:
            text = md_file.read_text(encoding="utf-8")
            for match in ASSET_REF_RE.finditer(text):
                rel = match.group(1)
                if "*" in rel or rel.endswith(".env"):
                    continue
                self.assertTrue((REPO_ROOT / rel).is_file(), f"Missing asset '{rel}' referenced in {md_file}")

        try:
            import yaml  # type: ignore
        except ImportError:
            yaml = None
        if yaml is not None:
            yml_files = sorted([*REPO_ROOT.rglob("*.yml"), *REPO_ROOT.rglob("*.yaml")])
            self.assertGreaterEqual(len(yml_files), 97)
            for yml_file in yml_files:
                docs = list(yaml.safe_load_all(yml_file.read_text(encoding="utf-8")))
                self.assertGreater(len(docs), 0, f"Empty YAML file: {yml_file}")

            acl_guide = (DOCS_DIR / "droits_comptes_rundeck.md").read_text(encoding="utf-8")
            acl_yaml_blocks = [b for b in _extract_fenced_blocks(acl_guide) if str(b["info"]).startswith("yaml")]
            self.assertGreaterEqual(len(acl_yaml_blocks), 5)
            for b in acl_yaml_blocks:
                parsed = list(yaml.safe_load_all(str(b["code"])))
                self.assertGreater(len(parsed), 0)

        py_compile.compile(str(REPO_ROOT / "scripts" / "crawl_site.py"), doraise=True)

        if os.name != "nt" and shutil.which("docker"):
            res = subprocess.run(
                [
                    "docker",
                    "compose",
                    "--env-file",
                    str(REPO_ROOT / "docker" / ".env.example"),
                    "-f",
                    str(REPO_ROOT / "docker" / "docker-compose.yml"),
                    "config",
                    "-q",
                ],
                capture_output=True,
                text=True,
                timeout=30,
            )
            self.assertEqual(res.returncode, 0, f"docker compose config failed: {res.stderr}")

        if os.name != "nt" and shutil.which("bash"):
            sh_files = sorted(REPO_ROOT.rglob("*.sh"))
            self.assertEqual(len(sh_files), 15)
            for sh_file in sh_files:
                res = subprocess.run(["bash", "-n", str(sh_file)], capture_output=True, text=True, timeout=15)
                self.assertEqual(res.returncode, 0, f"bash -n failed on {sh_file}: {res.stderr}")


if __name__ == "__main__":
    unittest.main()
