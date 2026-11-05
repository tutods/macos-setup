Orca embedded browser gotchas: input events, scrolling, hung tabs, screenshots.

## Input

- `orca click` and `orca keypress` can report success while no event reaches the page (pane not in the foreground). Drive the UI with DOM calls in `orca eval`: `el.click()`, `form.requestSubmit()`.
- React inputs: set the value through the native setter, then fire `input`:
  `Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, 'value').set.call(el, text); el.dispatchEvent(new Event('input', {bubbles: true}))` (use `HTMLInputElement.prototype` for inputs).
- Toggle widgets (popovers, accordions) flip on each click: read `aria-expanded` before clicking.

## Scrolling and hung tabs

- An occluded pane skips animation frames, so `scroll-behavior: smooth` leaves `scrollY` at 0. Pass `{behavior: 'instant'}` to `scrollTo` and `scrollBy`.
- A tab returning `runtime_unavailable` does not recover: `tab create` a fresh one and close the old one instead of retrying.

## Screenshots

- `full-screenshot` and oversized viewports tile into a mosaic. Take scroll-step screenshots at a normal viewport and stitch them with ImageMagick (`magick a.png b.png -append out.png`).
- After every `goto`, re-apply the viewport and assert `innerWidth` equals the target; navigation resets it to the native pane width.
- Wait about 3 s after load for hydration before scrolling, clicking or annotating.
