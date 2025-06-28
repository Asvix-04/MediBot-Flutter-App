# Medibot-flutter-app

# MediBot – Your Smart Health Companion

MediBot is a Flutter-based mobile application designed to help users manage their medicine schedules, health records, and summaries using AI assistance. The app supports Firebase Authentication, secure data handling, and intelligent health report generation.

---

## Features

- Login/Signup with Firebase Auth (Email/Password)
-  Add & track medicine reminders
-  View medicine schedules
-  AI-powered health report summarization
-  Secure storage with Firestore
-  Simple and modern UI
-  Session management with SharedPreferences

---


---

## CI/CD Workflow (GitHub → Firebase App Distribution)

This project uses **GitHub Actions** to automatically build and distribute the app through **Firebase App Distribution**.

###  What Happens:
- Every time code is pushed to `main`:
  - Flutter dependencies are installed
  - Release APK is built
  - APK is uploaded to Firebase

### How Testers Use It:
- Testers receive an **email invite** (Gmail) via Firebase
- Click the link → Sign in → Download the latest app build
- Install the APK (enable "Install unknown apps" once)

---

## Tech Stack

- **Framework**: Flutter 3.22
- **Backend**: Firebase (Auth, Firestore, App Distribution)
- **Language**: Dart
- **State Management**: setState (can migrate to Provider or Riverpod)
- **Others**: SharedPreferences, Form validation, Responsive layout

---

## How to Test the App (For Team/Testers)

1. Join the tester group using the Gmail invite sent via Firebase.
2. Open the download link on an Android device.
3. Sign in with your Gmail used for testing.
4. Tap **Download** to get the latest build.
5. Install the APK and start testing.

---

## For Developers

```bash
# Clone the repo
git clone https://github.com/Asvix-04/Medibot-Flutter-App.git

# Get packages
flutter pub get

# Run the app
flutter run
