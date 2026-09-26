#!/bin/bash
set -e

echo "=== Installing Flutter SDK ==="
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
fi

export PATH="$PATH:$HOME/flutter/bin"

echo "=== Flutter Version ==="
flutter --version

echo "=== Getting dependencies ==="
flutter pub get

echo "=== Building Flutter Web ==="
flutter build web --release --no-tree-shake-icons

echo "=== Build Complete ==="
