Text validation runbook: checks every human-read text passes before it ships, plus PT-PT language rules.

Scope: page and post content, SEO titles and metas, image alts, labels and chips, captions, emails, client documents, wp-admin strings customers see. Validate per text, never per batch.

## Steps

1. **Manual AI-writing pass** with both skills on every text: `unslop` (installed), then `avoid-ai-writing` (clone github.com/conorbronsdon/avoid-ai-writing fresh into the scratchpad, apply its `SKILL.md` and `references/patterns.md` by hand). The text passes when both find nothing. ZeroGPT in step 2 checks the result; a ZeroGPT fail sends the text back through both skills. The `avoid-ai-writing` detector is English-only: 0/Clean on Portuguese proves nothing. Report findings per text as P0/P1/P2, or "none"; a text with no line in the report counts as unchecked. The biggest tell: boxes, summaries and FAQ answers repeating the body or another page. Never change a literal product term to pass a scan.
2. **ZeroGPT**, one substantive text at a time, in your own Orca tab:
   - Reload the tab before each run; wait about 40 s between runs ("An Error occurred" otherwise).
   - Set the textarea with the native value setter plus an `input` event, JS-click the detect button, poll `document.body.innerText` for the percentage and label.
   - Target 0% and "Human written". "Mixed signals" counts as a fail: rewrite and rerun.
   - Only tiny strings (alts, chips, titles) may be combined into one labeled block; if the block shows mixed signals, run them one by one.
   - Spec tables are data: exempt from the 0% target. Never drop or reword spec rows to please the tool.
   - For pages, strip `<style>`, `<script>` and JSON-LD before scanning.
   - Weak evidence, never proof: in Portuguese it barely discriminates, so step 1 carries the weight. Report results as they came.
3. **PT-BR scan.** `python3 -I scripts/ptbr-scan.py <files>` (stdin works too). Prints `WORD` and `GERUND?` hits with context; exit code is always 0, so read the output. Follow with a manual read. Report the words found and replaced, or "none".
4. **Repeated phrases.** Scan for 3+ word n-grams repeated across the page's prose blocks (spec table and seals excluded) and across sibling pages or products. A fix in one block can create a repeat in another: rescan the whole page after any rewrite.
5. **Facts.** Never invent experiences, tests, measurements, sources, prices or stock. Every claim traces to a live page, maker spec or the client.

Rewrite only what fails, then rerun all steps on the changed text.

## PT-PT vocabulary

| Write | Never |
|---|---|
| ecrã | tela |
| telemóvel | celular |
| rato | mouse |
| ficheiro | arquivo |
| utilizador | usuário |
| equipa | equipe, time |
| registar | registrar |
| contacto | contato |
| transferir, descarregar | baixar |
| guardar | salvar |
| câmara | câmera |
| desporto, desportivo | esporte, esportivo |
| monitorizar | monitorar |
| auscultadores, auriculares | fones |
| aplicação | aplicativo |
| secção | seção |

- No gerunds: "está a fazer", "a adicionar", never "fazendo", "adicionando". Clitic after the verb: "Avise-me", "envie-nos".
- Spelling follows AO90 ("ótico", "ação", "direção"); "contacto" keeps its c.
- Decimals use a comma, product names included: 15,6″.
- Plugins (SEO, checkout, payment, consent) often ship PT-BR strings: never copy their wording.

## Voice and labels

- Customer copy is formal third person ("Receberá", "Pode confirmar"), never "você", never "tu".
- Email fields and links say **Email**: not "E-mail", "Correio" or "Correio eletrónico".
- A repeated label or section name has one canonical string everywhere (menus, headings, breadcrumbs, buttons). Counts need a singular form ("1 publicação").
- Enum values never leak in English: map every one to its PT-PT label.

## Dates

- Build pt-PT dates from parts (`Intl.DateTimeFormat('pt-PT', {timeZone: 'Europe/Lisbon', ...}).formatToParts`) and assemble them by hand; the default short formats vary by runtime.
- Always pass `timeZone: 'Europe/Lisbon'`: a server in UTC shifts dates near midnight.
