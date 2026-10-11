#!/bin/sh
# Build and launch Visual Paint (works with just the Command Line Tools).
set -e
cd "$(dirname "$0")"
mkdir -p .build
swiftc -O -parse-as-library -target "$(uname -m)-apple-macos13.0" \
    Sources/VisualPaint/VisualPaintApp.swift -o .build/VisualPaint
exec .build/VisualPaint
