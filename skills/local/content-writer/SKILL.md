---
name: content-writer
description: Use when writing blog posts, about pages, landing pages, FAQ sections, or social media posts. Trigger with "write content", "blog post", "about us", "landing page", "escreve conteúdo", "artigo", "página sobre nós". Writes in PT-PT (European Portuguese) by default. Produces human-like AI-undetectable content with outline-first workflow, mandatory web research, and always-on SEO metadata output.
---

# Content Writer — Human-First Content Creation

Write content that reads as 100% human-written. No AI patterns, no cliché phrases, no perfect structure. Five stages, in order. Do not skip ahead.

---

## STAGE 1 — INTAKE

Before doing anything else, collect all of the following. Ask in one message:

1. **Content type** — blog post / about page (person or company) / landing page / FAQ section / social media post (specify platform)
2. **Topic / theme** — what is this piece about?
3. **Language** — default is **PT-PT (European Portuguese)**; ask only if you suspect another language is needed
4. **Tone / voice** — pick one:
   - Conversational & direct (sounds like a real person talking)
   - Professional & neutral (corporate-safe, polished)
   - Expert & authoritative (confident, data-backed, minimal hedging)
5. **Target audience** — who reads this? Age, background, what do they care about?
6. **Relevant links** — URLs to reference, cite, or draw facts from (optional but encouraged)
7. **Personal angle** — any anecdote, opinion, or lived experience to embed? This is what makes content uniquely human. Even one sentence helps.
8. **Output format** — Markdown / plain text / HTML

Do not proceed to STAGE 2 until the user has answered all required fields (content type, topic, tone, audience are required; links and personal angle are optional).

---

## STAGE 2 — RESEARCH

Always search the web before writing. Never skip this stage.

Search for:
- Current facts, statistics, and data relevant to the topic (prefer sources from the last 12 months)
- Recent news or developments that add credibility
- 2-3 credible sources to cite or link inline
- If the user provided links in INTAKE: fetch and summarize each one — extract key facts, quotes, and angles

Summarize what you found in 3-5 bullet points before continuing. This transparency builds trust and lets the user correct bad sources.

---

## STAGE 3 — OUTLINE

Present a structured outline based on the content type. Use the templates in `templates.md` as the base structure. Adapt to the topic and angle.

Show the outline clearly — section titles + one-line description of what goes in each section.

Wait for explicit user approval. The user may:
- **Approve as-is** → proceed to STAGE 4
- **Request changes** → revise, re-present, wait again
- **Add/remove sections** → adjust and re-present

Do not draft until the outline is approved.

---

## STAGE 4 — DRAFT

Write the full piece. Follow these rules without exception:

### Language
Write in the language selected in STAGE 1. For PT-PT: use European Portuguese grammar, vocabulary, and spelling — not Brazilian Portuguese. Contractions and colloquial phrasing are fine for conversational tone.

### Human-First Writing Rules
- **Vary sentence length deliberately.** Short sentences land hard. Then a longer, more complex sentence that builds on the previous thought and adds nuance. Then short again.
- **Use rhetorical questions occasionally.** Not every paragraph — once or twice per piece.
- **Allow one-sentence paragraphs.** They create rhythm and emphasis.
- **Use contractions** (it's, you're, they've) for conversational and neutral tone.
- **Embed the personal angle** from INTAKE if provided — place it where it has the most impact, not just wherever it fits.
- **End strongly.** No "in conclusion". No summary of what you just said. End with a thought, a provocation, a call to action, or a question that stays with the reader.
- **First person OK** for personal/blog content. Third person for business content. Follow the tone selection.

### What Never to Write
Consult `blocklist.md` before writing and after writing. If any phrase from that list appears in the draft, replace it immediately. No exceptions.

### Structure
Follow the approved outline from STAGE 3. Section headers should feel natural, not generic. "Why Most Developers Get This Wrong" beats "Section 2: Common Mistakes".

---

## STAGE 5 — SEO METADATA

After the draft, always append this block — even if the user did not ask for it:

```
---
## SEO Metadata

**Meta description** (PT-PT, <160 chars):
[write it here]

**Target keywords** (3-5, ranked by priority):
1.
2.
3.

**Secondary keywords** (2-3):
-
-

**Suggested URL slug**:
[lowercase-hyphenated-no-accents]

**Suggested title tag** (<60 chars):
[write it here]
---
```

For PT-PT content: write the meta description in PT-PT. Keywords can be PT-PT or mixed if the search intent is bilingual.
