# Supabase Social Auth Setup Guide

This guide explains how to configure Google and Facebook authentication for your Flutter app using Supabase.

## 🚨 CRITICAL FIRST STEP: Supabase Redirect URLs

For mobile apps to receive the login callback, you **MUST** add the deep link to your Supabase whitelist.

1. Go to **Supabase Dashboard > Authentication > URL Configuration**.
2. Scroll to **Redirect URLs**.
3. Click **Add URI**.
4. Add: `io.supabase.flutter://callback`
5. Click **Save**.

*If you skip this, the app will try to redirect to localhost and fail (Connection Refused).*

---

## 1. Google Authentication Setup

### A. Google Cloud Console
1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project (or select existing).
3. Navigate to **APIs & Services > OAuth consent screen**.
    - Select **External** and click **Create**.
    - Fill in app details (Name, Support email).
    - Add Scopes: `.../auth/userinfo.email`, `.../auth/userinfo.profile`.
    - Add Test Users (if in testing mode).
4. Navigate to **Credentials**.
    - Click **Create Credentials** > **OAuth client ID**.
    - **Web Application** (for Supabase callback):
        - Name: "Supabase Auth"
        - Authorized redirect URIs: `https://<YOUR_PROJECT_REF>.supabase.co/auth/v1/callback`
        - **Copy the Client ID and Client Secret.**
    - **Android** (for native login):
        - Package name: `com.example.makaut_scholar` (check your `AndroidManifest.xml`)
        - SHA-1 Certificate fingerprint: Run `keytool -list -v -keystore android/app/debug.keystore` (password: `android`).
    - **iOS** (for native login):
        - Bundle ID: `com.example.makautScholar` (check your `Info.plist`).

### B. Supabase Dashboard
1. Go to **Authentication > Providers**.
2. Enable **Google**.
3. Paste the **Client ID** and **Client Secret** (from the Web Application credential).
4. (Optional) Toggle "Skip nonce check" if using native Google Sign-In SDK (advanced).
5. Click **Save**.

---

## 2. Facebook Authentication Setup

### A. Meta Developers
1. Go to [Meta for Developers](https://developers.facebook.com/).
2. Create a generic App.
3. Add **Facebook Login** product.
4. Go to **Facebook Login > Settings**.
5. Add Valid OAuth Redirect URIs: `https://<YOUR_PROJECT_REF>.supabase.co/auth/v1/callback`.
6. Go to **Settings > Basic**.
    - **Copy the App ID and App Secret.**
    - Add Platform > **iOS**:
        - Bundle ID: `com.example.makautScholar` (check `Info.plist`).
    - Add Platform > **Android**:
        - Google Play Package Name: `com.example.makaut_scholar`.
        - Class Name: `com.example.makaut_scholar.MainActivity`.
        - Key Hashes: Generate using `keytool` similar to Google (openssl required).

### B. Supabase Dashboard
1. Go to **Authentication > Providers**.
2. Enable **Facebook**.
3. Paste the **client_id** (App ID) and **client_secret** (App Secret).
4. Click **Save**.

---

## 3. Native Platform Configuration (Deep Linking)

For the login to redirect back to your app, you must configure deep linking.

### Android (`android/app/src/main/AndroidManifest.xml`)
Add this intent filter inside the `<activity>` tag:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="io.supabase.flutter" android:host="callback" />
</intent-filter>
```

### iOS (`ios/Runner/Info.plist`)
Add this inside the `<dict>` tag:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.flutter</string>
        </array>
    </dict>
</array>
```

*Note: Ensure `io.supabase.flutter` matches the scheme used in `AuthService`.*

---

## 4. Testing
- Run the app on a device/emulator.
- Tap the **Google** or **Facebook** button.
- It should open a browser window for authentication.
- Upon success, it should redirect back to the app and log you in.
