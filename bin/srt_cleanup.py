#!/usr/bin/env python3

import re
import os
from datetime import datetime, timedelta
import argparse
from dataclasses import dataclass

@dataclass
class Subtitle:
    start: datetime
    end: datetime
    text_lines: list[str]

def parse_srt(lines: list[str]) -> list[Subtitle | str]:
    """Parse SRT file into list of Subtitle objects."""
    subs = []
    i = 0
    while i < len(lines):
        if lines[i].strip() == '':
            i += 1
        elif i + 1 < len(lines) and '-->' in lines[i + 1]:
            start_time, end_time = [parse_time(t.strip()) for t in lines[i + 1].split('-->')]
            k = 2
            text_lines = []
            # all lines until the next empty line are the subtitle text
            while i + k < len(lines) and lines[i + k].strip() != '':
                text_lines.append(lines[i + k].strip())
                k += 1
            subs.append(Subtitle(start_time, end_time, text_lines))
            i += k
        else:
            subs.append(lines[i])
            i += 1
    return subs

def format_srt(subtitles: list[Subtitle | str]) -> list[str]:
    """Format list of Subtitle objects into SRT file."""
    subtitle_number = 1
    lines = []
    for item in subtitles:
        if isinstance(item, Subtitle):
            lines.append(f'{subtitle_number}\n')
            subtitle_number += 1
            lines.append(f'{time_to_str(item.start)} --> {time_to_str(item.end)}\n')
            lines.extend([f'{line}\n' for line in item.text_lines])
            lines.append('\n')
        else:
            lines.append(f'{item}\n')
    return lines

def parse_time(s):
    """Parse time from SRT time format."""
    return datetime.strptime(s, '%H:%M:%S,%f')

def time_to_str(t):
    """Convert time to SRT time format."""
    return t.strftime('%H:%M:%S,%f')[:-3]

def next_subtitle(subtitles: list[Subtitle | str], i: int) -> Subtitle | None:
    """Return next subtitle, or None if there is no next subtitle."""
    for j in range(i + 1, len(subtitles)):
        if isinstance(subtitles[j], Subtitle):
            return subtitles[j]
    return None

def prev_subtitle(subtitles: list[Subtitle | str], i: int) -> Subtitle | None:
    """Return previous subtitle, or None if there is no previous subtitle."""
    for j in range(i - 1, -1, -1):
        if isinstance(subtitles[j], Subtitle):
            return subtitles[j]
    return None

def overlaps_by(first: Subtitle, second: Subtitle) -> timedelta:
    """Calculate overlap between subtitles"""
    return max(first.end - second.start, timedelta(0))

@dataclass
class Subtitle:
    start: datetime
    end: datetime
    text_lines: list[str]

def has_ass_annotation(sub: Subtitle) -> bool:
    """Determines whether a Subtitle has an ass anotations (e.g. {\\an8})"""
    ass_pattern = re.compile(r'\{\\.*?\}')
    return any(ass_pattern.search(line) for line in sub.text_lines)

def remove_overlap(subtitles: list[Subtitle | str]) -> list[Subtitle | str]:
    """Adjust subtitles to remove overlap & get rid of subtitles that are less than 0.5 seconds in length"""
    result = []
    for i in range(len(subtitles)):
        if not isinstance(subtitles[i], Subtitle):
            result.append(subtitles[i])
            continue
        if not has_ass_annotation(subtitles[i]):
            result.append(subtitles[i])
            continue
        prev = prev_subtitle(subtitles, i)
        next = next_subtitle(subtitles, i)
        prev_overlap = overlaps_by(prev, subtitles[i]) if prev != None else None
        next_overlap = overlaps_by(subtitles[i], next) if next != None else None
        new_candidate = Subtitle(
            subtitles[i].start + prev_overlap if prev_overlap != None else subtitles[i].start,
            subtitles[i].end - next_overlap if next_overlap != None else subtitles[i].end,
            subtitles[i].text_lines
        )
        if (new_candidate.end - new_candidate.start).seconds > 0.5:
            result.append(new_candidate)
    return result

def remove_html(subtitles: list[Subtitle | str]) -> list[Subtitle | str]:
    for item in subtitles:
        if isinstance(item, Subtitle):
            item.text_lines = [re.sub(r'<[^>]+>', '', line) for line in item.text_lines]
    return subtitles

def remove_ass_annotations(subtitles: list[Subtitle | str]) -> list[Subtitle | str]:
    for item in subtitles:
        if isinstance(item, Subtitle):
            item.text_lines = [re.sub(r'{\\an\d}', '', line) for line in item.text_lines]
    return subtitles

def main():
    parser = argparse.ArgumentParser(description='Clean up SRT files that were converted from ASS files (i.e. with ffmpeg)')
    parser.add_argument('input_file', help='input file')
    parser.add_argument('output_file', help='output file')
    parser.add_argument('--no-overlap', action='store_false', dest='remove_overlap', help='don''t remove overlapping subtitles')
    parser.add_argument('--no-html', action='store_false', dest='remove_html', help='don''t remove HTML tags')
    args = parser.parse_args()

    with open(args.input_file, 'r', encoding='utf-8') as file:
        subtitles = parse_srt(file.readlines())

    if args.remove_overlap:
        subtitles = remove_overlap(subtitles)
    if args.remove_html:
        subtitles = remove_html(subtitles)
    subtitles = remove_ass_annotations(subtitles)

    with open(args.output_file, 'w', encoding='utf-8') as file:
        file.writelines(format_srt(subtitles))

if __name__ == "__main__":
    main()
