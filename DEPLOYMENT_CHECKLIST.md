# 📋 UniPerks Deployment Checklist

## Pre-Deployment ✅

- [ ] Update version in `pubspec.yaml`
  - Format: `version: 1.0.0+1` (Major.Minor.Patch+Build)

- [ ] Run analysis
  ```bash
  flutter analyze
  ```

- [ ] Run tests
  ```bash
  flutter test
  ```

- [ ] Clean build
  ```bash
  flutter clean
  flutter pub get
  ```

- [ ] Test on physical device
  - [ ] Android device
  - [ ] Test all core flows (login, order tracking, checkout)
  - [ ] Test payment integration (if enabled)

- [ ] Code review
  - [ ] Remove all debug prints: `print()` → Remove or wrap in `kDebugMode`
  - [ ] Check for TODO comments
  - [ ] Verify no hardcoded test credentials

- [ ] Security check
  - [ ] Verify Supabase keys (anon key only in client)
  - [ ] Verify Stripe keys (publishable key only in client)
  - [ ] Check RLS policies are enabled
  - [ ] Verify no sensitive data in logs

---

## Android APK (Direct Download) 📱

### Build Release APK
```bash
flutter build apk --release --no-shrink
```

### Output Location
```
build/app/outputs/flutter-apk/app-release.apk
```

### Share
1. **GitHub Releases** (Recommended)
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   # Upload APK in GitHub Releases UI
   ```
   Download: `https://github.com/Mahdiali97/uniperks/releases`

2. **Firebase Storage**
   ```bash
   firebase init storage
   gsutil cp build/app/outputs/flutter-apk/app-release.apk gs://bucket/app.apk
   ```

3. **Google Drive** (Direct link)

---

## Google Play Store 🎯

### Prerequisites
- [ ] Google Play Developer Account ($25)
- [ ] Signed APK/AAB
- [ ] App screenshots (4-6)
- [ ] App description
- [ ] Privacy policy URL
- [ ] Category & content rating

### Step 1: Generate Keystore
```bash
keytool -genkey -v -keystore ~/release.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 -alias release
```

### Step 2: Create `android/key.properties`
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=release
storeFile=path/to/release.keystore
```

### Step 3: Build App Bundle
```bash
flutter build appbundle --release
```

### Step 4: Upload to Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Go to **Release** → **Production**
4. Upload `build/app/outputs/bundle/release/app-release.aab`
5. Review and submit

### Step 5: Wait for Review
- 24-48 hours for approval
- Check Play Console for feedback

---

## Web Deployment 🌐

### Build Web
```bash
flutter build web --release --web-renderer canvaskit
```

### Option 1: Firebase Hosting (Recommended)

#### Setup
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
```

#### Deploy
```bash
flutter build web --release
firebase deploy --only hosting
```

**Live at**: `https://your-project.web.app`

---

### Option 2: Netlify (Easiest)
1. Build web: `flutter build web --release`
2. Go to [Netlify](https://netlify.com)
3. Drag & drop `build/web` folder
4. Done!

---

### Option 3: GitHub Pages (Free)
```bash
flutter build web --web-renderer html --release
# Push build/web to repository
```
Go to **Settings** → **Pages** → Enable

**Live at**: `https://Mahdiali97.github.io/uniperks`

---

## Desktop Deployment 🖥️

### Windows
```bash
flutter build windows --release
# Output: build/windows/runner/Release/
# Create installer with Inno Setup
```

### macOS
```bash
flutter build macos --release
# Output: build/macos/Build/Products/Release/
# Notarize and submit to App Store
```

### Linux
```bash
flutter build linux --release
# Output: build/linux/x64/release/bundle/
```

---

## Post-Deployment ✨

- [ ] Test downloaded APK on multiple devices
- [ ] Verify web app works on:
  - [ ] Chrome/Edge
  - [ ] Safari
  - [ ] Mobile browser
- [ ] Test payment flow (if applicable)
- [ ] Monitor Play Store reviews
- [ ] Set up crash reporting (Firebase Crashlytics)
- [ ] Monitor analytics

---

## Troubleshooting 🔧

### APK Won't Install
```bash
flutter build apk --release
# Try with different ABI
flutter build apk --release --target-platform android-arm64
```

### Web Issues
```bash
# Clear browser cache
# Try different renderer
flutter build web --release --web-renderer html
```

### Play Store Rejection
- Common reasons: missing privacy policy, screenshots, app crashes
- Check Play Console feedback
- Fix and resubmit

---

## Version Bump Workflow

### Update Version
Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2
```

### Commit
```bash
git add .
git commit -m "chore: bump to v1.0.1"
git tag v1.0.1
git push origin main v1.0.1
```

### Build & Deploy
```bash
flutter clean
flutter pub get
flutter build appbundle --release
flutter build web --release
```

---

## 📊 Deployment Summary

| Platform | Time | Cost | Users | Method |
|----------|------|------|-------|--------|
| Android APK | 10 min | Free | Direct | GitHub/Firebase |
| Google Play | 48 hrs | $25 | Large | Play Store |
| Web | 5 min | Free | Any browser | Firebase Hosting |
| Windows | 20 min | Free | Desktop | Direct download |

---

## 🔗 Quick Commands

```bash
# Full build & test cycle
flutter clean && flutter pub get && flutter analyze && flutter test

# Build all
flutter build apk --release && flutter build web --release && flutter build windows --release

# Deploy web to Firebase
firebase deploy --only hosting

# Create release tag
git tag v1.0.0 && git push origin v1.0.0
```

---

**Remember**: Always test thoroughly before deploying to production!
