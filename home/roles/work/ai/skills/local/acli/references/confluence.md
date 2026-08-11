# acli confluence — light reference

Verified against `acli version 1.3.22-stable`. Confluence surface here is
much smaller than Jira's — this file covers what exists, not a full workflow.

```sh
acli confluence auth status                 # separate auth from Jira's, check before use

acli confluence page view --id <PAGE_ID>                      # plain
acli confluence page view --id <PAGE_ID> --json                # structured
acli confluence page view --id <PAGE_ID> --body-format storage # raw storage-format XML body
acli confluence page view --id <PAGE_ID> --include-labels --include-version

acli confluence space list --json
acli confluence space view --key <SPACE_KEY> --json

acli confluence blog list --space <SPACE_KEY> --json
acli confluence blog view --id <BLOG_ID> --json
acli confluence blog create --space <SPACE_KEY> --title "..." --json
```

**`page` has only `view`** in this acli version — no `page create` or
`page update` subcommand exists. If asked to create or edit a Confluence
page, say so plainly rather than trying to force it through a flag that
doesn't exist; the user will need the Confluence UI, or a `blog` post if that
fits the content type instead.

`--body-format storage` on `page view` gets you Confluence storage-format
XHTML, which is the closest thing to "structured content" available here —
useful if summarizing or diffing a page's content, but it's XML-ish markup,
not Markdown or ADF.
