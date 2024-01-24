#!/usr/bin/env python3

import re
import os
from datetime import datetime, timedelta
import argparse

def parse_time(s):
    """Parse time from SRT time format."""
    return datetime.strptime(s, '%H:%M:%S,%f')

def time_to_str(t):
    """Convert time to SRT time format."""
    return t.strftime('%H:%M:%S,%f')[:-3]

def should_remove(prev_end, start, end, text):
    """Check if the subtitle should be removed."""
    if "{\\an" in text:
        if prev_end and (start - prev_end <= timedelta(seconds=0.5)):
            return True
        return False
    return False

def remove_overlap(lines):
    cleaned_lines = []
    prev_end_time = None

    i = 0
    while i < len(lines):
        if '-->' in lines[i]:
            start_time, end_time = [parse_time(t.strip()) for t in lines[i].split('-->')]
            text = ''.join(lines[i+1:i+3]).strip()

            if not should_remove(prev_end_time, start_time, end_time, text):
                cleaned_lines.extend(lines[i-1:i+3])
                prev_end_time = end_time

            i += 3
        else:
            i += 1

    return cleaned_lines

def remove_html(lines):
    cleaned_lines = [re.sub(r'<[^>]+>', '', line) for line in lines]
    return cleaned_lines

def remove_ass_annotations(lines):
    cleaned_lines = [re.sub(r'{\\an\d}', '', line) for line in lines]
    return cleaned_lines

def main():
    parser = argparse.ArgumentParser(description='Clean up SRT files that were converted from ASS files (i.e. with ffmpeg)')
    parser.add_argument('input_file', help='input file')
    parser.add_argument('output_file', help='output file')
    parser.add_argument('--no-overlap', action='store_false', dest='remove_overlap', help='don''t remove overlapping subtitles')
    parser.add_argument('--no-html', action='store_false', dest='remove_html', help='don''t remove HTML tags')
    args = parser.parse_args()

    with open(args.input_file, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    if args.remove_overlap:
        lines = remove_overlap(lines)
    if args.remove_html:
        lines = remove_html(lines)
    lines = remove_ass_annotations(lines)

    with open(args.output_file, 'w', encoding='utf-8') as file:
        file.writelines(lines)

if __name__ == "__main__":
    main()
