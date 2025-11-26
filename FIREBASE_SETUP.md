# Firebase Configuration Fix Guide

## The "Configuration Not Found" Error

This error occurs when **Email/Password authentication is not enabled** in Firebase Console for your app.

## Step-by-Step Fix:

### 1. Go to Firebase Console
- Open: https://console.firebase.google.com/
- Select your project: **prosfessorapp**

### 2. Enable Email/Password Authentication
1. Click on **"Authentication"** in the left sidebar
2. Click on the **"Sign-in method"** tab (at the top)
3. Find **"Email/Password"** in the list
4. Click on it
5. **Toggle the "Enable" switch** to ON
6. Click **"Save"**

### 3. Verify Your App is Registered
1. Go to **Project Settings** (gear icon next to "Project Overview")
2. Scroll down to **"Your apps"** section
3. Look for an Android app with:
   - Package name: `com.example.student_app`
   - App ID: `1:489385859664:android:72716120ac05fb9aa6cf55`
4. If this app doesn't exist, you need to add it:
   - Click "Add app" → Select Android
   - Package name: `com.example.student_app`
   - Download the new `google-services.json` and replace the one in `android/app/`

### 4. Rebuild Your App
After enabling Email/Password:
```bash
flutter clean
flutter pub get
flutter run
```

## Common Issues:

- **"Email/Password" not in the list?** → Make sure you're in the Authentication section, not Firestore
- **Can't find your app?** → The app might not be registered. Add it in Project Settings
- **Still getting errors?** → Check the debug console for specific error messages

## Verification:

After enabling Email/Password, try registering again. The error should be gone!

