#!/bin/bash
set -euo pipefail

export FLUTTER_HOME="${FLUTTER_HOME:-$HOME/.flutter}"
export PUB_CACHE="$FLUTTER_HOME/.pub-cache"

if [ ! -d "$FLUTTER_HOME" ]; then
  git clone --depth 1 https://github.com/flutter/flutter.git -b stable "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"

flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release
cp _redirects build/web/
