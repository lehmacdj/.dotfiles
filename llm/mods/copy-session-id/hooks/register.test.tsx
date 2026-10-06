import { expect, test } from 'claude-code/testing'
import type { TestBody } from 'claude-code/testing'
import type { On } from 'claude-code'

const SESSION_ID = '0b9c2f5e-1111-4222-8333-444455556666'

// Stands in for the engine beneath the plugin.
const engine = (on: On) => {
  on('session.id', () => ({ value: SESSION_ID }))
}

const mount = <S extends 'terminal' | 'desktop'>(
  $: Parameters<TestBody>[0],
  surface: S,
  modes: readonly string[] = [],
) =>
  $.ui.mount({
    plugin: 'copy-session-id',
    surface,
    component: 'SessionMode',
    props: { modes },
  })

for (const surface of ['terminal', 'desktop'] as const) {
  test(`copy sid button copies the full session id (${surface})`, async ($, on) => {
    engine(on)
    const copies: string[] = []
    const toasts: string[] = []
    on('ui.copy', (_$, e) => {
      copies.push(e.text)
      return { value: { isCopied: true } }
    })
    on('ui.toast', (_$, e, next) => {
      toasts.push(e.text)
      return next(e)
    })

    const ui = await mount($, surface)
    expect(await ui.find({ key: 'copy-id' })).toBeDefined()
    await ui.press({ key: 'copy-id' })

    expect(copies).toEqual([SESSION_ID])
    expect(toasts).toEqual(['Copied session id'])
  })

  test(`a failed copy is explained (${surface})`, async ($, on) => {
    engine(on)
    const toasts: string[] = []
    on('ui.copy', () => ({
      value: { isCopied: false, reason: 'no-clipboard' },
    }))
    on('ui.toast', (_$, e, next) => {
      toasts.push(e.text)
      return next(e)
    })

    const ui = await mount($, surface)
    await ui.press({ key: 'copy-id' })

    expect(toasts).toEqual([
      "Couldn't copy session id: no clipboard tool is available here " +
        '(no-clipboard)',
    ])
  })

  test(`keeps the engine's mode labels beside it (${surface})`, async ($, on) => {
    engine(on)
    const ui = await mount($, surface, ['focus', 'memory paused'])

    expect(await ui.find({ key: 'copy-id' })).toBeDefined()
    expect(await ui.find({ text: ' focus & memory paused' })).toBeDefined()
  })
}
