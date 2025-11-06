#!/bin/bash
echo "构建 Release 模式..."
flutter build ios --release --no-codesign
echo ""
echo "或者使用 Profile 模式测试性能:"
echo "flutter run --profile --no-sound-null-safety"
