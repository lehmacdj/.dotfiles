import type { Register, UiCopyResult } from 'claude-code'

// Human-readable form of each reason a copy can fail; the raw code is kept
// alongside it in the toast for diagnostics.
const describeFailure = (
  reason: Extract<UiCopyResult, { isCopied: false }>['reason'],
): string => {
  switch (reason) {
    case 'no-surface':
      return 'nothing is attached to draw on'
    case 'no-clipboard':
      return 'no clipboard tool is available here'
    case 'refused':
      return 'the copy was refused'
  }
}

export const register: Register = on => {
  // The status line's own row is not a site a mod can draw in; the mode labels
  // at the right end of the prompt footer are the nearest one, so the button
  // goes in front of them.
  on('ui.render', { component: 'SessionMode' }, async ($, e) => {
    const id = await $.session.id()
    const { Box, Button, Text } = $.ui.resolve(e)

    return (
      <Box>
        <Button
          key="copy-id"
          label="⧉ copy sid"
          plain
          onPress={async press => {
            const copied = await $.ui.copy({ text: id, surface: press.surface })
            $.ui.toast(
              copied.isCopied
                ? 'Copied session id'
                : `Couldn't copy session id: ` +
                    `${describeFailure(copied.reason)} (${copied.reason})`,
            )
          }}
        />
        {e.props.modes.length > 0 && (
          <Text dimColor> {e.props.modes.join(' & ')}</Text>
        )}
      </Box>
    )
  })
}
