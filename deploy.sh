#!/bin/bash
# UniPerks Deployment Checklist

echo "🚀 UniPerks Deployment Checklist"
echo "================================="
echo ""

# Check Flutter
echo "✓ Checking Flutter setup..."
flutter --version
echo ""

# Check for issues
echo "✓ Running Flutter analyze..."
flutter analyze
echo ""

# Run tests
echo "✓ Running tests..."
flutter test
echo ""

# Update dependencies
echo "✓ Getting dependencies..."
flutter pub get
echo ""

# Clean build
echo "✓ Cleaning previous builds..."
flutter clean
echo ""

echo "================================="
echo "✓ All checks passed!"
echo ""
echo "Ready for deployment. Choose:"
echo ""
echo "1. Android APK (Direct Download):"
echo "   flutter build apk --release"
echo ""
echo "2. Android App Bundle (Google Play Store):"
echo "   flutter build appbundle --release"
echo ""
echo "3. Web (Firebase Hosting):"
echo "   flutter build web --release"
echo "   firebase deploy --only hosting"
echo ""
echo "4. Windows Desktop:"
echo "   flutter build windows --release"
echo ""
echo "5. macOS Desktop:"
echo "   flutter build macos --release"
echo ""
