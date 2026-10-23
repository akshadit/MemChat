# 💬📁 MemChat — Conversational Cloud Storage

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat&logo=dart)](https://dart.dev/)
[![Google Drive API](https://img.shields.io/badge/Google_Drive_API-v3-4285F4?style=flat&logo=googledrive)](https://developers.google.com/drive)
[![Riverpod](https://img.shields.io/badge/State_Management-Riverpod-blueviolet)](https://riverpod.dev/)
[![Android](https://img.shields.io/badge/Platform-Android%20%7C%20Web-3DDC84?style=flat&logo=android)](https://www.android.com/)

> **Transform Google Drive into a sleek, WhatsApp-styled conversational workspace with instant native share intent interception.**

---

## 🌟 The Problem & The Solution

Traditional cloud storage platforms like Google Drive organize files into deeply nested, rigid folders that are clumsy to navigate and share on mobile. 

**MemChat** completely reimagines personal cloud storage by treating **Google Drive as a conversational messaging app**:
- Your Drive folders and categories behave like **WhatsApp chat threads**.
- Uploading files is as intuitive as sending a photo or voice note in a chat bubble.
- Includes a native Android share receiver: tap **"Share"** on any file in any app and drop it straight into MemChat without opening Drive!

---

## ✨ Key Features

- 🎨 **WhatsApp Dark Aesthetic**:
  - Immersive dark canvas with authentic WhatsApp-style doodle wallpaper (`whatsapp_doodle_background.dart`).
  - Familiar chat list screen, thread views, and formatted file bubbles with preview thumbnails.
- 🔄 **Google Drive as Backend**:
  - Uses your personal Google Drive storage via official `googleapis` and OAuth 2.0.
  - Zero proprietary lock-in: files remain yours in standard Google Drive folders.
- 📲 **Native Share Intent Interception**:
  - Built with `receive_sharing_intent`: forward pictures, PDFs, videos, or documents directly into MemChat from WhatsApp, Chrome, or the Gallery.
  - Destination modal allows picking which chat thread/category receives the upload.
- ⚡ **Instant File Viewer**:
  - Built-in previewing using `cached_network_image` and `open_filex` for external native viewers.
- 🌐 **Companion Website & APK Download**:
  - Ships with a landing page and direct APK download located in the `website/` directory.

---

## 🏗️ Project Architecture

```
lib/
├── main.dart                          # App entrypoint & theme initialization
├── models/
│   └── drive_item.dart               # Google Drive file & folder models
├── screens/
│   ├── splash_auth_screen.dart       # Google OAuth login & splash
│   ├── chat_list_screen.dart         # List of Drive folders as chat threads
│   ├── chat_thread_screen.dart       # Conversational file stream view
│   └── share_destination_modal.dart  # Modal for incoming Android shares
├── services/
│   ├── google_auth_service.dart      # Google Sign-In & token handling
│   ├── google_drive_service.dart     # Google Drive v3 API operations
│   └── share_intent_service.dart     # Native Android share intent listener
├── theme/
│   └── app_theme.dart                # WhatsApp-inspired dark palette
└── widgets/
    ├── file_bubble.dart              # Interactive file preview message bubble
    └── whatsapp_doodle_background.dart # Doodle pattern background
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK** (>= 3.11.5)
- **Android Studio** or **VS Code** with Flutter extensions
- A **Google Cloud Console Project** with the **Google Drive API (v3)** enabled

### 1. Clone the Repository
```bash
git clone https://github.com/akshadit/MemChat.git
cd MemChat
```

### 2. Configure Environment
Copy the example environment configuration:
```bash
cp .env.example .env
```
Fill in your Google Cloud OAuth Client IDs:
```env
GOOGLE_CLIENT_ID_WEB=your_web_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_ID_ANDROID=your_android_client_id.apps.googleusercontent.com
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run on Device / Emulator
```bash
flutter run
```

### 5. Build Release APK
```bash
flutter build apk --release
```
The generated APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📦 Dependencies

- `flutter_riverpod` — Reactive state management
- `google_sign_in` & `googleapis` — Google Drive v3 authentication and operations
- `extension_google_sign_in_as_googleapis_auth` — Authentication bridging
- `receive_sharing_intent` — Native Android file share interception
- `cached_network_image` & `open_filex` — Fast asset caching and file launch

---

## 📄 License

Licensed under the MIT License.