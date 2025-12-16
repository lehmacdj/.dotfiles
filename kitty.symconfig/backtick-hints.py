import re

def mark(text, args, Mark, extra_cli_args, *a):
    # Match text within backticks (single or triple)
    # Handles both `inline code` and ```code blocks```
    # We match the content inside the backticks, not the backticks themselves
    for idx, m in enumerate(re.finditer(r'```([^`]+)```|`([^`]+)`', text)):
        start, end = m.span()
        # Get the content inside backticks (group 1 for triple, group 2 for single)
        content = m.group(1) if m.group(1) else m.group(2)
        content = content.strip()
        if content:
            yield Mark(idx, start, end, content, {})


def handle_result(args, data, target_window_id, boss, extra_cli_args, *a):
    matches = [m for m in data['match'] if m]
    if not matches:
        return

    window = boss.window_id_map.get(target_window_id)
    if window:
        # Paste the selected text into the terminal
        for match_text in matches:
            window.paste_text(match_text)
