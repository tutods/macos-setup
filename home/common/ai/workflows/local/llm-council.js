export const meta = {
  name: 'llm-council',
  description: 'Five-advisor council: independent perspectives in parallel, blind peer review, chairman synthesis',
  whenToUse: 'Complex decisions needing structured divergent-then-convergent review. Pass the question as args.',
  phases: [
    { title: 'Advisors', detail: 'five independent perspectives in parallel' },
    { title: 'Peer Review', detail: 'blind review of anonymised responses' },
    { title: 'Chairman', detail: 'final recommendation, max 200 words' },
  ],
}

// The whole point of running this as a workflow instead of prose: each
// advisor answers in an isolated context, so they cannot converge on each
// other, and the anonymisation below happens in code, not on the honour
// system.

const question = typeof args === 'string' ? args : args && args.question
if (!question) {
  throw new Error('Pass the question as args: Workflow({scriptPath: ..., args: "<question>"})')
}

// Each advisor runs on a different model where it helps the lens: perspective
// diversity compounds with model diversity (identical models given different
// personas still share blind spots).
const ADVISORS = [
  {
    key: 'contrarian',
    model: 'opus',
    persona:
      'THE CONTRARIAN. Your only job is to find what will fail. Where does this break? What is the asker not seeing? What is the most likely failure mode? Be blunt.',
  },
  {
    key: 'first-principles',
    model: 'opus',
    persona:
      'THE FIRST PRINCIPLES THINKER. Strip away every assumption baked into the question. Rebuild the problem from scratch. What is actually being asked underneath the framing? Often the question itself is wrong.',
  },
  {
    key: 'expansionist',
    model: 'opus',
    persona:
      "THE EXPANSIONIST. Find the upside the asker is missing. What is the bigger version of this? What opportunity is hiding inside the question they haven't seen yet?",
  },
  {
    key: 'outsider',
    model: 'sonnet',
    persona:
      'THE OUTSIDER. You have zero context about this industry, role, or situation. Respond as a smart generalist seeing this for the first time. What looks weird from the outside? What are insiders taking for granted?',
  },
  {
    key: 'executor',
    model: 'haiku',
    persona:
      'THE EXECUTOR. You only care about Monday morning. Skip the theory. What is the single concrete action to take first? What is the smallest version of this that can ship this week?',
  },
]

phase('Advisors')
const answers = await parallel(
  ADVISORS.map((a) => () =>
    agent(
      `You are one advisor on a five-person council. Stay fully in character and commit to your lens completely, no hedging, no "on the other hand".

YOUR CHARACTER: ${a.persona}

THE QUESTION:
${question}

Answer in under 300 words. Your final text is returned as raw data, no greeting, no meta-commentary, just the answer.`,
      { label: `advisor:${a.key}${a.model ? `@${a.model}` : ''}`, phase: 'Advisors', model: a.model }
    )
  )
)

const responses = ADVISORS.map((a, i) => ({ advisor: a.key, text: answers[i] })).filter((r) => r.text)
if (responses.length < 3) {
  throw new Error(`Only ${responses.length}/5 advisors responded, not enough for a meaningful council.`)
}

// Anonymise: the reviewer sees only shuffled letter labels, never advisor
// names. Math.random is unavailable (breaks resume), so rotate by question
// length, position bias is what matters, and the reviewer has no way to
// map labels back to personas either way.
const labels = ['A', 'B', 'C', 'D', 'E']
const offset = question.length % responses.length
const shuffled = responses.map((_, i) => ({
  label: labels[i],
  text: responses[(i + offset) % responses.length].text,
}))

phase('Peer Review')
const review = await agent(
  `You are a neutral reviewer. Below are ${shuffled.length} anonymous responses to this question:

"${question}"

${shuffled.map((s) => `RESPONSE ${s.label}:\n${s.text}`).join('\n\n')}

Answer exactly three questions:
1. Which response is strongest, and why?
2. Which response has the biggest blind spot, and what is it?
3. What did all the responses miss?

Your final text is returned as raw data, just the three answers.`,
  { label: 'peer-review', phase: 'Peer Review', model: 'opus' }
)

phase('Chairman')
const recommendation = await agent(
  `You are the Chairman of a five-advisor council. Read everything below and give:
- A final recommendation in plain language
- The single most important reason behind it
- One concrete next step to take today

No more than 200 words. Your final text is returned as raw data.

THE QUESTION:
${question}

ADVISOR RESPONSES:
${responses.map((r) => `${r.advisor.toUpperCase()}:\n${r.text}`).join('\n\n')}

PEER REVIEW:
${review}`,
  { label: 'chairman', phase: 'Chairman', model: 'opus' }
)

return { question, advisors: responses, review, recommendation }
