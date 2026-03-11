#!/bin/bash
git clone https://github.com/flutter/flutter.git -b 3.24.0 --depth 1 $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"
flutter precache --web
flutter build web --release
