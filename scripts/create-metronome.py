#!/usr/bin/env python3
"""
Minimal metronome MIDI generator (stdlib only)
"""

import struct
import sys

def write_varlen(n):
    bytes_ = []
    bytes_.append(n & 0x7F)
    n >>= 7
    while n:
        bytes_.insert(0, (n & 0x7F) | 0x80)
        n >>= 7
    return bytes_

def note_event(note, velocity, delta=0, on=True):
    status = 0x90 if on else 0x80
    return write_varlen(delta) + [status, note, velocity]

def meta_event(event_type, data, delta=0):
    return write_varlen(delta) + [0xFF, event_type, len(data)] + data

def create_metronome(filename, bpm=120, beats_per_bar=4, bars=4, ppqn=480):
    tempo = int(60_000_000 / bpm)  # microseconds per quarter note

    header = b'MThd' + struct.pack('>IHHH', 6, 1, 1, ppqn)

    track_data = []

    track_data += meta_event(0x51, [(tempo >> 16) & 0xFF, (tempo >> 8) & 0xFF, tempo & 0xFF])

    for bar in range(bars):
        for beat in range(beats_per_bar):
            note = 46 if beat == 0 else 42  # high C for downbeat
            track_data += note_event(note, 100, delta=0, on=True)
            track_data += note_event(note, 0, delta=ppqn, on=False)  # quarter note

    track_data += meta_event(0x2F, [], delta=0)

    track_bytes = bytes(track_data)
    track_chunk = b'MTrk' + struct.pack('>I', len(track_bytes)) + track_bytes

    with open(filename, 'wb') as f:
        f.write(header + track_chunk)

if __name__ == "__main__":
    bpm = 120
    if len(sys.argv) > 1:
        try:
            bpm = int(sys.argv[1])
        except ValueError:
            print("Invalid BPM, using default 120")
    create_metronome("metronome.mid", bpm=bpm, beats_per_bar=4, bars=8)
    print("Metronome MIDI file 'metronome.mid' created.")
