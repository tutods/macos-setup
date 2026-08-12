## Project Rules — a-optica

Live path is `~/Developer/freelances/a-optica`. `~/Developer/AI/a-optica` is a
dead checkout (empty except `.idea`) — never mine it for context.

### Sanity / GROQ

Shape data in the query, never in TypeScript afterwards:

- Defaults via `coalesce()` in the projection
- Portable Text → string via `pt::text()` in the query
- **No post-query `??` wrapper helpers.** This has been corrected repeatedly.

```groq
// Wrong: getSafePageData(result) applying ?? to every field
// Right:
{ "title": coalesce(hero.title, "") }
```

### Images

`@unpic/react` handles preload and LQIP through its own props (`background`,
`priority`). Hand-rolled lazy-loading or preload tricks around it broke the hero
image twice — revert `68a7ca8`, fix `8e2ec74`. Configure the component; do not
work around it.

### Library APIs

Check current API names before using anything remembered from training data —
`inputValidator` was deprecated in favour of `validator` (`5bff831`). Fetch the
docs first.

### Git

This repo often has uncommitted work in the tree. Commit with an explicit
pathspec so a staged deletion doesn't get swept into an unrelated commit — that
has happened twice here.

```bash
git commit -m "…" -- path/to/file
```
