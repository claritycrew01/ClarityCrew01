#!/bin/bash
set -euo pipefail

# Install Flutter if not already cached
if [ ! -d "/opt/flutter" ]; then
  git clone --depth 1 https://github.com/flutter/flutter.git -b stable /opt/flutter
fi
export PATH="/opt/flutter/bin:$PATH"
export PUB_CACHE="/opt/flutter/.pub-cache"

flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release
cp _redirects build/web/
