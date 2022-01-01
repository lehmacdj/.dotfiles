#!/usr/bin/env python3

from mutagen.mp3 import MP3
import sys

if len(sys.argv) < 2:
    print('error: didn\'t pass enough arguments')
    print('usage: ./bitrate.py <file name>')
    print('usage: find the bitrate of an mp3 file')
    exit(1)

f = MP3(sys.argv[1])
print('bitrate: %s' % (f.info.bitrate / 1000))
