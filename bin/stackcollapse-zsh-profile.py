#!/usr/bin/env python3
"""
Convert zsh profiler output to flamegraph format.

Takes zsh profiler output and converts it to the stack-collapsed format
expected by flamegraph.pl for visualization.
"""

import re
import sys
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
from pathlib import Path


@dataclass
class ProfileLine:
    """Represents a single line from zsh profiler output."""
    timestamp: float
    location: str
    command: str

    @classmethod
    def parse(cls, line: str) -> Optional['ProfileLine']:
        """Parse a zsh profiler line into components."""
        # Pattern: +timestamp location> command
        match = re.match(r'\+(\d+\.\d+)\s+([^>]+)>\s*(.*)', line.strip())
        if not match:
            return None

        timestamp = float(match.group(1))
        location = match.group(2).strip()
        command = match.group(3).strip()

        return cls(timestamp, location, command)


@dataclass
class StackFrame:
    """Represents a frame in the execution stack."""
    context: str  # File path or function name
    line_number: Optional[int] = None
    source_line: Optional[int] = None  # Line number from which this was sourced

    def format_frame(self, parent_frame: Optional['StackFrame'] = None) -> str:
        """Format this frame for flamegraph output."""
        if parent_frame and self.source_line and '/' in self.context:
            # This is a sourced file, annotate with source line
            return f"{parent_frame.context}:{self.source_line}@{self.context}"
        return self.context


class ZshProfiler:
    """Processes zsh profiler output into flamegraph format."""

    def __init__(self):
        self.stack_traces: List[Tuple[str, int]] = []  # (stack_trace, duration_ms)

    def parse_location(self, location: str) -> Tuple[str, Optional[int]]:
        """Parse location into context and line number."""
        if ':' in location:
            parts = location.split(':', 1)
            context = parts[0]
            try:
                line_num = int(parts[1].split('>')[0])
                return context, line_num
            except (ValueError, IndexError):
                return context, None
        return location, None

    def is_source_command(self, command: str) -> bool:
        """Check if command is sourcing a file."""
        return command.startswith('source ') or command.startswith('. ')

    def extract_sourced_file(self, command: str) -> Optional[str]:
        """Extract the file path from a source command."""
        if command.startswith('source '):
            return command[7:].strip().split()[0]
        elif command.startswith('. '):
            return command[2:].strip().split()[0]
        return None

    def is_function_call(self, command: str, location: str) -> bool:
        """Check if this command is a function call."""
        if '/' not in location:  # Not called from a file
            return False

        cmd = command.strip().split()[0] if command.strip() else ""

        # Skip obvious non-functions
        excluded = {'export', 'mkdir', 'uname', 'case', 'fpath', 'eval', 'PATH',
                   'MANPATH', 'autoload', '[', 'test', 'emulate'}

        if cmd in excluded or '=' in command or '/' in cmd:
            return False

        return True

    def should_pop_stack(self, stack: List[StackFrame], current_location: str) -> int:
        """Determine how many frames to pop from the stack. Returns number of frames to pop."""
        if not stack:
            return 0

        current_context, current_line = self.parse_location(current_location)

        # Check if we've returned to a parent frame by comparing line numbers
        for i in range(len(stack) - 1, -1, -1):
            frame = stack[i]

            # If we're back in the same file with a higher line number
            if (frame.context == current_context and
                frame.line_number is not None and
                current_line is not None and
                current_line > frame.line_number):
                # Pop everything after this frame
                return len(stack) - i - 1

        return 0

    def process_file(self, filepath: str) -> List[Tuple[str, int]]:
        """Process entire zsh profiler file."""
        lines = []

        with open(filepath, 'r') as f:
            for line_text in f:
                line = ProfileLine.parse(line_text)
                if line:
                    lines.append(line)

        if not lines:
            return []

        call_stack: List[StackFrame] = []

        for i in range(len(lines)):
            current_line = lines[i]
            current_context, current_line_num = self.parse_location(current_line.location)

            # Calculate duration to next line
            if i + 1 < len(lines):
                next_line = lines[i + 1]
                duration_ms = int((next_line.timestamp - current_line.timestamp) * 1000000)
            else:
                duration_ms = 1

            if duration_ms <= 0:
                duration_ms = 1

            # Pop frames if we've returned to a parent context
            frames_to_pop = self.should_pop_stack(call_stack, current_line.location)
            for _ in range(frames_to_pop):
                call_stack.pop()

            # Handle new file contexts
            if '/' in current_context:
                # Check if this is a new file context
                if not call_stack or call_stack[-1].context != current_context:
                    # Look back to see if this was sourced
                    source_line_num = None
                    for j in range(max(0, i - 5), i):
                        prev_line = lines[j]
                        if (self.is_source_command(prev_line.command) and
                            self.extract_sourced_file(prev_line.command) == current_context):
                            _, source_line_num = self.parse_location(prev_line.location)
                            break

                    new_frame = StackFrame(
                        context=current_context,
                        line_number=current_line_num,
                        source_line=source_line_num
                    )
                    call_stack.append(new_frame)

            # Handle function calls
            elif not current_context.startswith('/'):
                # This is a function - check if it was just called
                func_name = current_context
                if not call_stack or call_stack[-1].context != func_name:
                    # Look back for the function call
                    for j in range(max(0, i - 3), i):
                        prev_line = lines[j]
                        if (self.is_function_call(prev_line.command, prev_line.location) and
                            prev_line.command.strip().split()[0] == func_name):
                            new_frame = StackFrame(context=func_name, line_number=current_line_num)
                            call_stack.append(new_frame)
                            break

            # Build the stack trace
            stack_parts = []
            for j, frame in enumerate(call_stack):
                if j == 0:
                    stack_parts.append(frame.context)
                else:
                    parent_frame = call_stack[j - 1]
                    formatted = frame.format_frame(parent_frame)
                    stack_parts.append(formatted)

            # Add the command as the final stack frame with line number and full command
            command_word = current_line.command.strip().split()[0] if current_line.command.strip() else '(empty)'
            full_command = current_line.command.strip() if current_line.command.strip() else '(empty)'
            stack_parts.append(command_word)
            final_frame = f"{current_line_num}:{full_command}"
            stack_parts.append(final_frame)

            stack_string = ';'.join(stack_parts)
            self.stack_traces.append((stack_string, duration_ms))

        return self.stack_traces

    def to_flamegraph_format(self) -> str:
        """Convert to flamegraph format."""
        result = []
        for stack, duration in self.stack_traces:
            result.append(f"{stack} {duration}")
        return '\n'.join(result)


def main():
    """Main entry point."""
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <zsh_profile_file>", file=sys.stderr)
        sys.exit(1)

    profiler = ZshProfiler()
    profiler.process_file(sys.argv[1])

    if not profiler.stack_traces:
        print("No valid profile data found", file=sys.stderr)
        sys.exit(1)

    print(profiler.to_flamegraph_format())


if __name__ == '__main__':
    main()
