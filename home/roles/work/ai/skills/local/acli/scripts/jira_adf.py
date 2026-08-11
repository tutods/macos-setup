#!/usr/bin/env python3
"""Markdown -> Atlassian Document Format (ADF), and ADF -> acli payloads.

Jira renders ADF, not Markdown. Hand-writing ADF JSON is where most acli
mistakes happen: the payload is accepted (no validation error) but renders as
a wall of unstructured text, because a `type` or nesting level was off. This
script is the only place ADF gets built.

Subcommands:
  doc <file.md>                 -> ADF doc JSON on stdout
  create [flags]                -> full `acli jira workitem create --from-json` payload
  edit [flags]                  -> full `acli jira workitem edit --from-json` payload
  comment <file.md>             -> ADF doc JSON on stdout (pass to comment create --body-file)

Stdlib only, Python 3.8+.
"""
import argparse
import json
import re
import sys


HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")
# Task items: "- [ ] text", "- [x] text", or the bare "[ ] text" / "[] text"
# variant that shows up constantly in ticket descriptions typed by hand.
TASK_RE = re.compile(r"^\s*(?:[-*]\s*)?\[([ xX]?)\]\s+(.*)$")
BULLET_RE = re.compile(r"^\s*[-*]\s+(.*)$")
ORDERED_RE = re.compile(r"^\s*\d+[.)]\s+(.*)$")
RULE_RE = re.compile(r"^\s*(-{3,}|\*{3,}|_{3,})\s*$")
FENCE_RE = re.compile(r"^```(\w*)\s*$")

INLINE_CODE_RE = re.compile(r"`([^`]+)`")
BOLD_RE = re.compile(r"\*\*([^*]+)\*\*")
ITALIC_RE = re.compile(r"(?<!\*)\*([^*]+)\*(?!\*)")
LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")


def parse_inline(text):
    """Split a line into ADF text nodes, applying marks for **bold**, *italic*,
    `code`, and [link](url). Order matters: code first so markup inside code
    spans isn't reinterpreted.
    """
    tokens = [(text, ())]

    def split_on(pattern, tokens, mark):
        out = []
        for chunk, marks in tokens:
            if mark in marks:
                out.append((chunk, marks))
                continue
            pos = 0
            for m in pattern.finditer(chunk):
                if m.start() > pos:
                    out.append((chunk[pos:m.start()], marks))
                out.append((m.group(1), marks + (mark,)))
                pos = m.end()
            if pos < len(chunk):
                out.append((chunk[pos:], marks))
        return out

    # Links need special handling since they carry a URL, not just a mark name.
    def split_links(tokens):
        out = []
        for chunk, marks in tokens:
            if "link" in marks:
                out.append((chunk, marks))
                continue
            pos = 0
            for m in LINK_RE.finditer(chunk):
                if m.start() > pos:
                    out.append((chunk[pos:m.start()], marks))
                out.append((m.group(1), marks + (("link", m.group(2)),)))
                pos = m.end()
            if pos < len(chunk):
                out.append((chunk[pos:], marks))
        return out

    tokens = split_on(INLINE_CODE_RE, tokens, "code")
    tokens = split_on(BOLD_RE, tokens, "strong")
    tokens = split_on(ITALIC_RE, tokens, "em")
    tokens = split_links(tokens)

    nodes = []
    for chunk, marks in tokens:
        if not chunk:
            continue
        node = {"type": "text", "text": chunk}
        adf_marks = []
        for mark in marks:
            if isinstance(mark, tuple):
                adf_marks.append({"type": "link", "attrs": {"href": mark[1]}})
            else:
                adf_marks.append({"type": mark})
        if adf_marks:
            node["marks"] = adf_marks
        nodes.append(node)
    return nodes or [{"type": "text", "text": ""}]


def paragraph(text):
    return {"type": "paragraph", "content": parse_inline(text)}


def markdown_to_adf(markdown_text):
    lines = markdown_text.splitlines()
    content = []
    i = 0
    local_id_counter = [0]

    def next_local_id(prefix):
        local_id_counter[0] += 1
        return f"{prefix}-{local_id_counter[0]}"

    while i < len(lines):
        line = lines[i]

        if not line.strip():
            i += 1
            continue

        m = RULE_RE.match(line)
        if m:
            content.append({"type": "rule"})
            i += 1
            continue

        m = FENCE_RE.match(line)
        if m:
            language = m.group(1) or None
            i += 1
            code_lines = []
            while i < len(lines) and not FENCE_RE.match(lines[i]):
                code_lines.append(lines[i])
                i += 1
            i += 1  # skip closing fence
            node = {"type": "codeBlock", "content": [{"type": "text", "text": "\n".join(code_lines)}]}
            if language:
                node["attrs"] = {"language": language}
            content.append(node)
            continue

        m = HEADING_RE.match(line)
        if m:
            level = len(m.group(1))
            content.append({
                "type": "heading",
                "attrs": {"level": level},
                "content": parse_inline(m.group(2)),
            })
            i += 1
            continue

        if TASK_RE.match(line):
            items = []
            while i < len(lines) and TASK_RE.match(lines[i]):
                tm = TASK_RE.match(lines[i])
                state = "DONE" if tm.group(1).lower() == "x" else "TODO"
                items.append({
                    "type": "taskItem",
                    "attrs": {"localId": next_local_id("task"), "state": state},
                    "content": parse_inline(tm.group(2)),
                })
                i += 1
            content.append({
                "type": "taskList",
                "attrs": {"localId": next_local_id("tasklist")},
                "content": items,
            })
            continue

        if BULLET_RE.match(line):
            items = []
            while i < len(lines) and BULLET_RE.match(lines[i]) and not TASK_RE.match(lines[i]):
                bm = BULLET_RE.match(lines[i])
                items.append({"type": "listItem", "content": [paragraph(bm.group(1))]})
                i += 1
            content.append({"type": "bulletList", "content": items})
            continue

        if ORDERED_RE.match(line):
            items = []
            while i < len(lines) and ORDERED_RE.match(lines[i]):
                om = ORDERED_RE.match(lines[i])
                items.append({"type": "listItem", "content": [paragraph(om.group(1))]})
                i += 1
            content.append({"type": "orderedList", "content": items})
            continue

        # Plain paragraph: consume until a blank line or a line that starts a
        # different block, joining wrapped lines with a space.
        para_lines = [line.strip()]
        i += 1
        while i < len(lines) and lines[i].strip() and not any(
            p.match(lines[i]) for p in (HEADING_RE, TASK_RE, BULLET_RE, ORDERED_RE, RULE_RE, FENCE_RE)
        ):
            para_lines.append(lines[i].strip())
            i += 1
        content.append(paragraph(" ".join(para_lines)))

    if not content:
        content = [paragraph("")]

    return {"version": 1, "type": "doc", "content": content}


def read_md(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def cmd_doc(args):
    print(json.dumps(markdown_to_adf(read_md(args.file)), indent=2))


def cmd_comment(args):
    # Same shape as `doc` — acli's `comment create --body-file` accepts a raw
    # ADF doc JSON file directly (verified against acli 1.3.22).
    print(json.dumps(markdown_to_adf(read_md(args.file)), indent=2))


def parse_field(raw):
    key, _, value = raw.partition("=")
    if not _:
        raise ValueError(f"--field expects key=value, got: {raw!r}")
    # Bare value -> string; JSON-looking value (array/object/number/bool) -> parsed.
    stripped = value.strip()
    if stripped[:1] in "[{" or stripped in ("true", "false", "null") or re.fullmatch(r"-?\d+(\.\d+)?", stripped or ""):
        try:
            return key, json.loads(stripped)
        except json.JSONDecodeError:
            return key, value
    return key, value


def cmd_create(args):
    payload = {
        "projectKey": args.project,
        "type": args.type,
        "summary": args.summary,
    }
    if args.description_md:
        payload["description"] = markdown_to_adf(read_md(args.description_md))
    if args.assignee:
        payload["assignee"] = args.assignee
    if args.reporter:
        payload["reporter"] = args.reporter
    if args.parent:
        payload["parentIssueId"] = args.parent
    if args.label:
        payload["labels"] = [label.strip() for label in args.label.split(",") if label.strip()]
    if args.field:
        additional = {}
        for raw in args.field:
            key, value = parse_field(raw)
            additional[key] = value
        payload["additionalAttributes"] = additional
    print(json.dumps(payload, indent=2))


def cmd_edit(args):
    payload = {"issues": [args.key]}
    if args.summary:
        payload["summary"] = args.summary
    if args.type:
        payload["type"] = args.type
    if args.description_md:
        payload["description"] = markdown_to_adf(read_md(args.description_md))
    if args.assignee:
        payload["assignee"] = args.assignee
    if args.add_label:
        payload["labelsToAdd"] = [label.strip() for label in args.add_label.split(",") if label.strip()]
    if args.remove_label:
        payload["labelsToRemove"] = [label.strip() for label in args.remove_label.split(",") if label.strip()]
    # NOTE: `additionalAttributes` is deliberately not supported here.
    # Verified against acli 1.3.22: `edit --from-json` with an
    # `additionalAttributes` key fails with `unknown field "additionalAttributes"`.
    # Custom fields can only be set on create.
    print(json.dumps(payload, indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    doc_parser = sub.add_parser("doc", help="Convert a Markdown file to an ADF doc")
    doc_parser.add_argument("file")
    doc_parser.set_defaults(func=cmd_doc)

    comment_parser = sub.add_parser("comment", help="Convert a Markdown file to an ADF doc for comment --body-file")
    comment_parser.add_argument("file")
    comment_parser.set_defaults(func=cmd_comment)

    create_parser = sub.add_parser("create", help="Build a full workitem create --from-json payload")
    create_parser.add_argument("--project", required=True)
    create_parser.add_argument("--type", required=True)
    create_parser.add_argument("--summary", required=True)
    create_parser.add_argument("--description-md")
    create_parser.add_argument("--assignee")
    create_parser.add_argument("--reporter")
    create_parser.add_argument("--parent", help="parentIssueId, for sub-tasks")
    create_parser.add_argument("--label", help="comma-separated")
    create_parser.add_argument("--field", action="append", default=[], help="customfield_XXXXX=value, repeatable")
    create_parser.set_defaults(func=cmd_create)

    edit_parser = sub.add_parser("edit", help="Build a full workitem edit --from-json payload")
    edit_parser.add_argument("--key", required=True)
    edit_parser.add_argument("--summary")
    edit_parser.add_argument("--type")
    edit_parser.add_argument("--description-md")
    edit_parser.add_argument("--assignee")
    edit_parser.add_argument("--add-label", help="comma-separated")
    edit_parser.add_argument("--remove-label", help="comma-separated")
    edit_parser.set_defaults(func=cmd_edit)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
