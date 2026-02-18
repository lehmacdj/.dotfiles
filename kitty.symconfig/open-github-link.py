import re
import subprocess
import os
import sys

def mark(text, args, Mark, extra_cli_args, *a):
    # This function is responsible for finding all
    # matching text. extra_cli_args are any extra arguments
    # passed on the command line when invoking the kitten.
    # We mark all PR references like #14811 (GitHub style)
    for idx, m in enumerate(re.finditer(r'#(\d+)', text)):
        start, end = m.span()
        mark_text = text[start:end].replace('\n', '').replace('\0', '')
        # Store the PR number in groupdicts for use in handle_result
        pr_number = m.group(1)
        yield Mark(idx, start, end, mark_text, {'pr_number': pr_number})


def get_github_repo_from_git(cwd):
    """Get the GitHub repo from git config."""
    try:
        result = subprocess.run(
            ['git', 'config', '--get', 'remote.origin.url'],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=1
        )
        if result.returncode == 0:
            remote_url = result.stdout.strip()
            # Parse GitHub URL (handles both SSH and HTTPS formats)
            # SSH: git@github.com:owner/repo.git
            # HTTPS: https://github.com/owner/repo.git
            if 'github.com' in remote_url:
                # Extract owner/repo
                match = re.search(r'github\.com[:/]([^/]+/[^/]+?)(?:\.git)?$', remote_url)
                if match:
                    return match.group(1)
    except (subprocess.TimeoutExpired, FileNotFoundError, Exception):
        pass
    return None


def get_github_repo_from_jj(cwd):
    """Get the GitHub repo from jj git remote list."""
    try:
        result = subprocess.run(
            ['jj', 'git', 'remote', 'list'],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=1
        )
        if result.returncode == 0:
            # Parse jj output: "origin https://github.com/owner/repo.git"
            for line in result.stdout.strip().split('\n'):
                if 'github.com' in line:
                    # Extract the URL from the line
                    match = re.search(r'github\.com[:/]([^/]+/[^/]+?)(?:\.git)?(?:\s|$)', line)
                    if match:
                        return match.group(1)
    except (subprocess.TimeoutExpired, FileNotFoundError, Exception):
        pass
    return None


def get_github_repo(cwd):
    """Get the GitHub repo from the current working directory's git/jj config."""
    # Try jj first, then fall back to git
    repo = get_github_repo_from_jj(cwd)
    if repo:
        return repo
    return get_github_repo_from_git(cwd)


def warn_user(boss, message):
    """Display a warning to the user without failing the kitten."""
    try:
        if hasattr(boss, 'show_error'):
            boss.show_error('GitHub Link Warning', message)
            return
    except Exception:
        pass
    print(f'GitHub link warning: {message}', file=sys.stderr)


def handle_result(args, data, target_window_id, boss, extra_cli_args, *a):
    # This function is responsible for performing some
    # action on the selected text.
    # matches is a list of the selected entries and groupdicts contains
    # the arbitrary data associated with each entry in mark() above
    matches, groupdicts = [], []
    for m, g in zip(data['match'], data['groupdicts']):
        if m:
            matches.append(m), groupdicts.append(g)

    # Get the current working directory from the active window
    window = boss.window_id_map.get(target_window_id)
    cwd = window.child.foreground_processes[0]['cwd'] if window and window.child.foreground_processes else os.getcwd()

    # Detect the GitHub repo from git/jj config
    github_repo = get_github_repo(cwd)

    # Gracefully do nothing if we can't detect the repo.
    if not github_repo:
        warn_user(boss, f'Could not determine GitHub repository for: {cwd}')
        return

    for match_text, match_data in zip(matches, groupdicts):
        # Extract the PR number from the groupdicts and open the GitHub PR URL
        pr_number = match_data['pr_number']
        boss.open_url(f'https://github.com/{github_repo}/pull/{pr_number}')
