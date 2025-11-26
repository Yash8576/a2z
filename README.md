# hub_flux

A new Flutter project.

## 🖥️ Cross-Platform Setup (Mac & Windows)

This project is configured to work seamlessly on both Mac and Windows using Git.

### Prerequisites

**On Mac:**
```bash
# Flutter SDK should be at: ~/flutter
# Android SDK should be at: ~/Library/Android/sdk
```

**On Windows:**
```bash
# Flutter SDK should be at: C:\src\flutter (or add to PATH)
# Android SDK should be at: C:\Users\YourName\AppData\Local\Android\sdk
```

### First Time Setup

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd a2z
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run from Android Studio**
   - Open the project in Android Studio
   - Select your device/emulator from the top toolbar
   - Click the green ▶️ Run button
   - Or press `Shift+F10` (Windows) / `Control+R` (Mac)

### Important Files for Cross-Platform
- `.idea/runConfigurations/` - Shared run configurations (committed to Git)
- `.gitignore` - Configured to keep run configs but ignore workspace files

## Getting Started

# Hub Flux 🚀

A Flutter app with Firebase Authentication and Cloud Firestore, built using MAANG-level best practices.

## ✨ Features

- ✅ Firebase Authentication (Email/Password)
- ✅ Cloud Firestore real-time database
- ✅ Repository pattern architecture
- ✅ Stream-based reactive UI
- ✅ O(1) time complexity operations
- ✅ Proper memory management (no leaks)
- ✅ Type-safe code throughout
- ✅ Comprehensive error handling

## 🏗️ Architecture

```
lib/
├── main.dart                 # App entry point, Firebase init
├── repositories/             # Data layer (MAANG pattern)
│   ├── auth_repository.dart  # Authentication logic
│   └── user_repository.dart  # Firestore operations
└── ui/                       # Presentation layer
    ├── sign_in_screen.dart   # Login/Signup UI
    └── home_screen.dart      # User profile screen
```

**Clean Architecture**: UI → Repository → Firebase

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.10+
- Firebase project created
- Android Studio / VS Code

### Setup (5 minutes)

1. **Clone and install dependencies**
   ```bash
   flutter pub get
   ```

2. **Firebase Console Setup**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Enable Email/Password Authentication
   - Create Firestore database in test mode

3. **Run**
   ```bash
   flutter run
   ```

See [QUICKSTART.md](QUICKSTART.md) for detailed instructions.

## 📚 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Get started in 3 minutes
- **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)** - Complete setup guide
- **[MAANG_PRINCIPLES.md](MAANG_PRINCIPLES.md)** - Architecture & interview prep
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Visual diagrams
- **[CHECKLIST.md](CHECKLIST.md)** - Setup verification

## 🎯 MAANG-Level Practices

### Time Complexity
- Authentication: **O(1)** per operation
- Firestore operations: **O(1)** per document
- UI updates: **O(1)** with StreamBuilder

### Space Complexity
- Memory: **O(1)** per screen (proper disposal)
- Storage: **O(1)** per user document
- No memory leaks (all controllers disposed)

### Design Patterns
- **Repository Pattern** - Testable, maintainable
- **Stream-Based State** - Reactive, efficient
- **Error Handling** - Centralized, user-friendly

## 🔧 Tech Stack

- **Flutter** - Cross-platform UI framework
- **Firebase Auth** - User authentication
- **Cloud Firestore** - NoSQL database
- **Dart** - Programming language

## 🧪 Testing

```bash
# Run tests (when added)
flutter test

# Check code quality
flutter analyze

# Check for issues
flutter doctor
```

## 📱 Features Roadmap

- [x] Authentication (Email/Password)
- [x] User profile storage
- [x] Real-time data sync
- [ ] Profile editing
- [ ] Posts/Feed system
- [ ] Image upload (local)
- [ ] Push notifications
- [ ] Email verification

## 🤝 Contributing

This is a learning project demonstrating MAANG-level best practices. Feel free to:
- Study the architecture
- Learn from the code
- Use it as a template for your projects

## 📄 License

MIT License - see LICENSE file for details

## 🎓 Learning Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [MAANG Interview Prep](MAANG_PRINCIPLES.md)

## 🙏 Acknowledgments

Built with inspiration from MAANG company engineering practices:
- Clean architecture
- Performance optimization
- Scalability considerations
- Security best practices

---

**Built with ❤️ using Flutter and Firebase**
