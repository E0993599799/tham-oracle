#!/usr/bin/env python3
"""Build a compact repo second-brain index for the HTML viewer.

The index is intentionally lightweight:
- file metadata
- symbols / headings / sections
- local dependency edges
- a recommended reading tour

It does not require tree-sitter or any external package.
"""

from __future__ import annotations

import ast
import argparse
import hashlib
import json
import os
import re
import subprocess
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

IGNORED_DIRS = {
    ".git",
    "node_modules",
    "__pycache__",
    ".venv",
    ".next",
    "dist",
    "build",
    "coverage",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
    "logs",
    "proofs",
}

ALLOWED_EXTS = {
    ".py",
    ".js",
    ".jsx",
    ".ts",
    ".tsx",
    ".md",
    ".html",
    ".sh",
    ".json",
}

JS_FUNCTION_RE = re.compile(r"^\s*(?:export\s+)?(?:async\s+)?function\s+([A-Za-z_$][\w$]*)\s*\(")
JS_CLASS_RE = re.compile(r"^\s*(?:export\s+)?class\s+([A-Za-z_$][\w$]*)\b")
JS_ARROW_RE = re.compile(
    r"^\s*(?:export\s+)?(?:const|let|var)\s+([A-Za-z_$][\w$]*)\s*=\s*(?:async\s*)?(?:\([^\)]*\)|[A-Za-z_$][\w$]*)\s*=>"
)
JS_IMPORT_RE = re.compile(r"^\s*import\s+.*?from\s+['\"]([^'\"]+)['\"]")
JS_REQUIRE_RE = re.compile(r"require\(['\"]([^'\"]+)['\"]\)")
MD_HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*$")
HTML_TITLE_RE = re.compile(r"<title>(.*?)</title>", re.I | re.S)
HTML_HEADING_RE = re.compile(r"<h([1-3])[^>]*>(.*?)</h\1>", re.I | re.S)
PY_IMPORT_FROM_RE = re.compile(r"^from\s+([A-Za-z_][\w.]*)\s+import\s+")
PY_IMPORT_RE = re.compile(r"^import\s+([A-Za-z_][\w.]*)")


@dataclass
class Node:
    id: str
    kind: str
    name: str
    path: str
    line: int | None = None
    summary: str = ""
    meta: dict = field(default_factory=dict)


@dataclass
class Edge:
    source: str
    target: str
    kind: str
    label: str = ""


def run_git_files(root: Path, exclude: set[str] | None = None) -> list[Path]:
    exclude = exclude or set()
    try:
        output = subprocess.check_output(
            ["git", "-C", str(root), "ls-files", "-co", "--exclude-standard"],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except Exception:
        paths: list[Path] = []
        for current, dirs, files in os.walk(root):
            dirs[:] = [d for d in dirs if d not in IGNORED_DIRS and not d.startswith(".")]
            for filename in files:
                path = Path(current) / filename
                if path.suffix.lower() in ALLOWED_EXTS:
                    paths.append(path)
        return sorted(paths)

    result: list[Path] = []
    for line in output.splitlines():
        rel = line.strip()
        if not rel:
            continue
        path = root / rel
        if not path.exists() or not path.is_file():
            continue
        if any(part in IGNORED_DIRS for part in path.parts):
            continue
        if path.suffix.lower() not in ALLOWED_EXTS:
            continue
        if safe_relpath(path, root) in exclude:
            continue
        result.append(path)
    return sorted(result)


def clean_text(text: str, max_len: int = 140) -> str:
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) <= max_len:
        return text
    return text[: max_len - 1].rstrip() + "…"


def safe_relpath(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def make_id(kind: str, path: str, name: str, line: int | None) -> str:
    raw = f"{kind}|{path}|{name}|{line or 0}"
    return hashlib.sha1(raw.encode("utf-8")).hexdigest()[:12]


def preview_from_lines(lines: list[str], index: int, radius: int = 1) -> str:
    if not lines:
        return ""
    start = max(0, index - radius)
    end = min(len(lines), index + radius + 1)
    snippet = " ".join(line.strip() for line in lines[start:end] if line.strip())
    return clean_text(snippet, 180)


def add_file_node(nodes: list[Node], rel: str, kind: str, name: str, line: int | None, summary: str, meta: dict | None = None) -> str:
    node_id = make_id(kind, rel, name, line)
    nodes.append(
        Node(
            id=node_id,
            kind=kind,
            name=name,
            path=rel,
            line=line,
            summary=summary,
            meta=meta or {},
        )
    )
    return node_id


def extract_python(path: Path, rel: str, text: str, nodes: list[Node], edges: list[Edge], root: Path) -> dict:
    try:
        tree = ast.parse(text)
    except SyntaxError:
        return {"symbols": 0, "imports": 0}

    lines = text.splitlines()
    symbol_count = 0
    import_count = 0

    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            summary = ast.get_docstring(node) or preview_from_lines(lines, max(node.lineno - 1, 0))
            add_file_node(
                nodes,
                rel,
                "symbol",
                node.name,
                getattr(node, "lineno", None),
                summary,
                {"language": "python", "symbol_type": type(node).__name__},
            )
            symbol_count += 1
        elif isinstance(node, ast.Import):
            import_count += 1
            for alias in node.names:
                target = resolve_python_import(root, rel, alias.name)
                if target:
                    edges.append(Edge(source=rel, target=target, kind="imports", label=alias.name))
        elif isinstance(node, ast.ImportFrom):
            import_count += 1
            base = node.module or ""
            target = resolve_python_import(root, rel, base)
            if target:
                edges.append(Edge(source=rel, target=target, kind="imports", label=base or "."))

    return {"symbols": symbol_count, "imports": import_count}


def extract_js_like(path: Path, rel: str, text: str, nodes: list[Node], edges: list[Edge], root: Path) -> dict:
    lines = text.splitlines()
    symbol_count = 0
    import_count = 0

    for idx, line in enumerate(lines):
        match = JS_FUNCTION_RE.match(line) or JS_CLASS_RE.match(line) or JS_ARROW_RE.match(line)
        if match:
            name = match.group(1)
            summary = preview_from_lines(lines, idx)
            add_file_node(
                nodes,
                rel,
                "symbol",
                name,
                idx + 1,
                summary,
                {"language": path.suffix.lower().lstrip("."), "line_preview": clean_text(line)},
            )
            symbol_count += 1

        m_import = JS_IMPORT_RE.match(line)
        if m_import:
            import_count += 1
            spec = m_import.group(1)
            target = resolve_js_import(root, rel, spec)
            if target:
                edges.append(Edge(source=rel, target=target, kind="imports", label=spec))

        for req in JS_REQUIRE_RE.findall(line):
            import_count += 1
            target = resolve_js_import(root, rel, req)
            if target:
                edges.append(Edge(source=rel, target=target, kind="requires", label=req))

    return {"symbols": symbol_count, "imports": import_count}


def extract_markdown(path: Path, rel: str, text: str, nodes: list[Node], edges: list[Edge], root: Path) -> dict:
    lines = text.splitlines()
    heading_count = 0
    link_count = 0

    for idx, line in enumerate(lines):
        m = MD_HEADING_RE.match(line)
        if m:
            level = len(m.group(1))
            title = m.group(2).strip()
            add_file_node(
                nodes,
                rel,
                f"heading-h{level}",
                title,
                idx + 1,
                preview_from_lines(lines, idx),
                {"level": level, "language": "markdown"},
            )
            heading_count += 1

        for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", line):
            if not target or target.startswith(("http://", "https://", "mailto:")):
                continue
            resolved = resolve_relative_link(root, rel, target)
            if resolved:
                edges.append(Edge(source=rel, target=resolved, kind="links", label=target))
                link_count += 1

    return {"headings": heading_count, "links": link_count}


def extract_html(path: Path, rel: str, text: str, nodes: list[Node], edges: list[Edge], root: Path) -> dict:
    title = HTML_TITLE_RE.search(text)
    if title:
        add_file_node(nodes, rel, "title", clean_text(title.group(1)), 1, clean_text(title.group(1), 180), {"language": "html"})

    heading_count = 0
    for match in HTML_HEADING_RE.finditer(text):
        level = int(match.group(1))
        heading = re.sub(r"<[^>]+>", "", match.group(2))
        line = text[: match.start()].count("\n") + 1
        add_file_node(
            nodes,
            rel,
            f"heading-h{level}",
            clean_text(heading),
            line,
            clean_text(heading, 180),
            {"level": level, "language": "html"},
        )
        heading_count += 1

    return {"headings": heading_count}


def resolve_relative_link(root: Path, source_rel: str, target: str) -> str | None:
    target_path = root / Path(source_rel).parent / target
    if target_path.suffix:
        return target_path.relative_to(root).as_posix() if target_path.is_relative_to(root) else None
    for suffix in (".md", ".html", ".py", ".js", ".ts", ".tsx", ".json"):
        candidate = target_path.with_suffix(suffix)
        if candidate.exists():
            return candidate.relative_to(root).as_posix() if candidate.is_relative_to(root) else None
    for candidate in (target_path / "index.md", target_path / "index.html"):
        if candidate.exists():
            return candidate.relative_to(root).as_posix() if candidate.is_relative_to(root) else None
    return None


def resolve_js_import(root: Path, source_rel: str, spec: str) -> str | None:
    if not spec.startswith((".", "/")):
        return None
    base = root / Path(source_rel).parent / spec
    candidates = []
    if base.suffix:
        candidates.append(base)
    else:
        candidates.extend(
            [
                base.with_suffix(".js"),
                base.with_suffix(".ts"),
                base.with_suffix(".tsx"),
                base.with_suffix(".mjs"),
                base.with_suffix(".cjs"),
                base / "index.js",
                base / "index.ts",
                base / "index.tsx",
            ]
        )
    for candidate in candidates:
        if candidate.exists():
            return candidate.relative_to(root).as_posix() if candidate.is_relative_to(root) else None
    return None


def resolve_python_import(root: Path, source_rel: str, module: str) -> str | None:
    if not module:
        return None
    base = Path(module.replace(".", "/"))
    candidates = [root / base.with_suffix(".py"), root / base / "__init__.py"]
    for candidate in candidates:
        if candidate.exists():
            return candidate.relative_to(root).as_posix() if candidate.is_relative_to(root) else None
    # Try relative to the current file's package root
    source_dir = root / Path(source_rel).parent
    pkg_candidate = source_dir / base.with_suffix(".py")
    if pkg_candidate.exists():
        return pkg_candidate.relative_to(root).as_posix() if pkg_candidate.is_relative_to(root) else None
    return None


def compute_depths(file_edges: dict[str, set[str]], files: list[str]) -> dict[str, int]:
    memo: dict[str, int] = {}
    visiting: set[str] = set()

    def depth(path: str) -> int:
        if path in memo:
            return memo[path]
        if path in visiting:
            return 0
        visiting.add(path)
        children = file_edges.get(path, set())
        if not children:
            value = 0
        else:
            value = 1 + max(depth(child) for child in children)
        visiting.remove(path)
        memo[path] = value
        return value

    for file_path in files:
        depth(file_path)
    return memo


def build_index(root: Path, exclude: set[str] | None = None) -> dict:
    files = run_git_files(root, exclude=exclude)
    nodes: list[Node] = []
    edges: list[Edge] = []
    file_records: list[dict] = []
    node_type_counts: Counter[str] = Counter()
    ext_counts: Counter[str] = Counter()
    file_dependency_map: dict[str, set[str]] = defaultdict(set)
    inbound_counts: Counter[str] = Counter()

    for path in files:
        rel = safe_relpath(path, root)
        ext = path.suffix.lower()
        ext_counts[ext or "[none]"] += 1
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        except OSError:
            continue

        file_summary = clean_text(text.splitlines()[0] if text.splitlines() else "", 120)
        file_node_id = add_file_node(nodes, rel, "file", path.name, 1, file_summary, {"language": ext.lstrip(".")})
        node_type_counts["file"] += 1

        local_stats = {"symbols": 0, "imports": 0, "headings": 0, "links": 0}
        if ext == ".py":
            local_stats.update(extract_python(path, rel, text, nodes, edges, root))
        elif ext in {".js", ".jsx", ".ts", ".tsx"}:
            local_stats.update(extract_js_like(path, rel, text, nodes, edges, root))
        elif ext == ".md":
            local_stats.update(extract_markdown(path, rel, text, nodes, edges, root))
        elif ext == ".html":
            local_stats.update(extract_html(path, rel, text, nodes, edges, root))

        file_records.append(
            {
                "path": rel,
                "name": path.name,
                "ext": ext or "",
                "size": len(text.encode("utf-8")),
                "line_count": text.count("\n") + 1,
                "summary": file_summary,
                "stats": local_stats,
            }
        )

    # Filter edge targets to files present in the index and aggregate dependency maps.
    file_set = {item["path"] for item in file_records}
    deduped_edges: list[Edge] = []
    seen_edges: set[tuple[str, str, str, str]] = set()
    for edge in edges:
        if edge.source not in file_set or edge.target not in file_set:
            continue
        key = (edge.source, edge.target, edge.kind, edge.label)
        if key in seen_edges:
            continue
        seen_edges.add(key)
        deduped_edges.append(edge)
        file_dependency_map[edge.source].add(edge.target)
        inbound_counts[edge.target] += 1

    file_depths = compute_depths(file_dependency_map, sorted(file_set))
    files_by_score = sorted(
        file_records,
        key=lambda item: (
            -file_depths.get(item["path"], 0),
            -(item["stats"]["symbols"] + item["stats"]["headings"]),
            item["path"],
        ),
    )

    tour = []
    for item in files_by_score[:40]:
        tour.append(
            {
                "path": item["path"],
                "name": item["name"],
                "depth": file_depths.get(item["path"], 0),
                "inbound": inbound_counts.get(item["path"], 0),
                "symbols": item["stats"].get("symbols", 0),
                "headings": item["stats"].get("headings", 0),
                "summary": item["summary"],
            }
        )

    kind_counts = Counter(node.kind for node in nodes)
    edges_payload = [edge.__dict__ for edge in deduped_edges]
    nodes_payload = [node.__dict__ for node in nodes]
    digest = hashlib.sha1(
        json.dumps({"nodes": nodes_payload, "edges": edges_payload}, sort_keys=True, ensure_ascii=False).encode("utf-8")
    ).hexdigest()

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "repo_root": str(root),
        "hash": digest,
        "counts": {
            "files": len(file_records),
            "nodes": len(nodes_payload),
            "edges": len(edges_payload),
            "symbols": kind_counts.get("symbol", 0),
            "headings": sum(1 for node in nodes if node.kind.startswith("heading-")),
        },
        "kind_counts": dict(kind_counts),
        "ext_counts": dict(ext_counts),
        "files": sorted(file_records, key=lambda item: item["path"]),
        "nodes": nodes_payload,
        "edges": edges_payload,
        "tour": tour,
        "depths": file_depths,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Build the repo second-brain index.")
    parser.add_argument("--root", default=".", help="Repository root")
    parser.add_argument("--output", default="dashboard/brain-index.json", help="Output JSON file")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    output = Path(args.output)
    if not output.is_absolute():
        output = (root / output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)

    exclude = {safe_relpath(output, root)} if output.is_relative_to(root) else set()
    index = build_index(root, exclude=exclude)
    output.write_text(json.dumps(index, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"ok": True, "output": str(output), "files": index["counts"]["files"], "nodes": index["counts"]["nodes"]}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
