# UniPerks Deployment Guide

Complete guide to deploy and distribute your Flutter application across multiple platforms.

---

## 📱 **ANDROID DEPLOYMENT**

### **Option 1: Direct APK Distribution (Fastest)**

#### Build Release APK
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Share APK
- Upload to file hosting (GitHub Releases, Firebase Storage, Google Drive)
- Users download and install via `adb install app-release.apk` or direct tap

#### Build App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

### **Option 2: Google Play Store (Recommended)**

#### Step 1: Setup Google Play Account
- Go to [Google Play Console](https://play.google.com/console)
- Create developer account ($25 one-time fee)
- Create new app

#### Step 2: Prepare App Signing

**Generate keystore** (one-time):
```bash
keytool -genkey -v -keystore ~/UniPerks.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias uniperks
```

**Create `android/key.properties`**:
```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=uniperks
storeFile=/path/to/UniPerks.keystore
```

#### Step 3: Build App Bundle
```bash
flutter build appbundle --release
```

#### Step 4: Upload to Play Store Console
- Sign in to Play Console
- Go to Release > Production
- Upload `app-release.aab`
- Fill in store listing, screenshots, description
- Submit for review (24-48 hours)

---

## 🌐 **WEB DEPLOYMENT**

### **Build Web**
```bash
flutter build web --release
```

Output: `build/web/`

### **Option 1: Firebase Hosting (Free, Recommended)**

#### Setup Firebase
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
```

#### Deploy
```bash
firebase deploy --only hosting
```

Your app is live at: `https://your-project.web.app`

---

### **Option 2: Netlify (Free, Easy)**

#### Build & Deploy
```bash
flutter build web --release
```

1. Go to [Netlify](https://netlify.com)
2. Drag & drop `build/web` folder
3. Done! Get instant URL

---

### **Option 3: GitHub Pages (Free)**

#### Build
```bash
flutter build web --web-renderer html --release
```

#### Push to GitHub
```bash
git add build/web
git commit -m "Deploy web version"
git push origin main
```

#### Enable GitHub Pages
- Go to repository Settings > Pages
- Select `main` branch, `/docs` folder
- Your site is live at: `https://Mahdiali97.github.io/uniperks`

---

## 🖥️ **DESKTOP DEPLOYMENT**

### **Windows Build**
```bash
flutter build windows --release
```

Output: `build/windows/runner/Release/`

Create installer with [Inno Setup](https://jrsoftware.org/isinfo.php)

---

### **macOS Build**
```bash
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/`

Notarize for App Store via Xcode

---

### **Linux Build**
```bash
flutter build linux --release
```

Output: `build/linux/x64/release/bundle/`

---

## 📦 **APK DIRECT DOWNLOAD SETUP**

### **Host on GitHub Releases (Free)**

#### 1. Build Release APK
```bash
flutter build apk --release
```

#### 2. Create GitHub Release
```bash
git tag v1.0.0
git push origin v1.0.0
```

#### 3. Upload APK
- Go to GitHub repo > Releases
- Create new release
- Upload `app-release.apk`
- Users can download directly

**Download Link**: `https://github.com/Mahdiali97/uniperks/releases/download/v1.0.0/app-release.apk`

---

### **Host on Firebase Storage**

#### 1. Setup Firebase
```bash
firebase init storage
```

#### 2. Upload APK
```bash
gsutil cp build/app/outputs/flutter-apk/app-release.apk gs://your-bucket/app-release.apk
```

#### 3. Generate Download Link
- Publicly accessible at: `https://storage.googleapis.com/your-bucket/app-release.apk`

---

## 🔐 **PRE-DEPLOYMENT CHECKLIST**

- [ ] Update `pubspec.yaml` version
- [ ] Run `flutter pub get`
- [ ] Run `flutter analyze` (no errors/warnings)
- [ ] Run `flutter test` (all tests pass)
- [ ] Test on real device/emulator
- [ ] Update app name in `android/app/build.gradle` and `pubspec.yaml`
- [ ] Verify Supabase credentials (remove test keys)
- [ ] Test all payment features (Stripe)
- [ ] Verify RLS policies in Supabase
- [ ] Test login/registration flows
- [ ] Clear debug prints from code

---

## 📝 **VERSION UPDATE WORKFLOW**

### Update Version
Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

Format: `MAJOR.MINOR.PATCH+BUILD`

### Build All Platforms
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# Web
flutter build web --release

# Desktop (Windows)
flutter build windows --release
```

---

## 🚀 **RECOMMENDED DEPLOYMENT STRATEGY**

### **For Production:**

1. **Mobile (Android)**
   - Use Google Play Store for main distribution
   - GitHub Releases for beta/APK direct download
   - Link: Play Store URL or GitHub release

2. **Web**
   - Deploy to Firebase Hosting (free, reliable)
   - Custom domain: `app.yourdomain.com`
   - Link: https://your-project.web.app

3. **Desktop**
   - Windows: Inno Setup installer on GitHub Releases
   - macOS: App Store or direct DMG

---

## 📊 **QUICK START: DEPLOY IN 5 MINUTES**

### Android APK (Direct Download)
```bash
flutter build apk --release
# Share build/app/outputs/flutter-apk/app-release.apk
```

### Web (Firebase)
```bash
flutter build web --release
firebase deploy --only hosting
```

### Check Deployment
```bash
flutter --version
flutter doctor
```

---

## 🔗 **USEFUL LINKS**

- [Flutter Build Docs](https://docs.flutter.dev/deployment)
- [Google Play Console](https://play.google.com/console)
- [Firebase Hosting](https://firebase.google.com/products/hosting)
- [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github)

---

## ❓ **COMMON QUESTIONS**

### **Q: How do users install Android APK?**
A: Download APK → Open file manager → Tap APK → "Install" → Done

### **Q: Can I update the app after deployment?**
A: Yes. Build new version, increment version number, rebuild & deploy.

### **Q: Is my Supabase data secure?**
A: Yes. Use RLS policies, never expose private keys, use anon key for clients.

### **Q: How much does it cost?**
A: Firebase Hosting (free tier), GitHub (free), Google Play ($25 one-time).

