#!/bin/sh
# Mac/Linux: webcam head tracking for local testing. Double-click on Mac, or run in a terminal.
# The first run installs everything it needs (needs Python 3 and internet).
cd "$(dirname "$0")"
if [ ! -f .venv/installed ]; then
    python3 -m venv .venv && .venv/bin/pip install -r requirements.txt && touch .venv/installed || exit 1
fi
.venv/bin/python head_sender.py --preview "$@"
