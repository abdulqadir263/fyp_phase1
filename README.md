# Aasaan Kisaan

A comprehensive Flutter application integrating Firebase backend services, AI-powered features, and cloud-based image management.  This project represents Phase 1 of a Final Year Project, demonstrating modern mobile app development practices with cross-platform support.

## 🚀 Features

### Core Functionality
- **Firebase Integration**: Real-time database operations with Cloud Firestore
- **Authentication System**: Secure user authentication via Firebase Auth
- **AI-Powered Features**: Integration with Google Generative AI for intelligent functionalities
- **Image Management**: Cloud-based image storage and optimization using Cloudinary
- **Location Services**: Geolocation tracking and location-based features
- **State Management**: Efficient state management using GetX architecture

### User Experience
- **Modern UI**: Custom fonts using Google Fonts
- **Image Handling**: Pick, upload, and cache images efficiently
- **Loading States**: Beautiful loading indicators with Flutter SpinKit
- **User Feedback**: Toast notifications for user interactions
- **Offline Support**: Local data persistence with SharedPreferences
- **Responsive Design**: Optimized for multiple screen sizes and platforms

## 📱 Platform Support

This application supports the following platforms:
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🛠️ Technology Stack

### Framework & Language
- **Flutter SDK**: ^3.9.2
- **Dart**: Primary programming language (64.6% of codebase)

### Key Dependencies

#### Firebase Services
- `firebase_core`: ^4.2.0 - Firebase initialization
- `firebase_auth`: ^6.1.1 - User authentication
- `cloud_firestore`: ^6.0.3 - NoSQL cloud database

#### State Management & Navigation
- `get`: ^4. 7.2 - State management, dependency injection, and route management

#### AI & Machine Learning
- `google_generative_ai`: ^0.2.2 - AI-powered features and content generation

#### Image Processing
- `image_picker`: ^1.2. 0 - Select images from gallery or camera
- `cloudinary_flutter`: ^1.3.0 - Cloud-based image management
- `cached_network_image`: ^3.3.1 - Efficient image caching

#### UI Components
- `google_fonts`: ^6.3.2 - Custom typography
- `flutter_spinkit`: ^5.2.0 - Elegant loading animations
- `fluttertoast`: ^8.2. 4 - User notifications

#### Utilities
- `geolocator`: ^14.0.2 - Location services
- `intl`: ^0.20.2 - Internationalization and date formatting
- `http`: ^1.5.0 - HTTP client for API requests
- `flutter_dotenv`: ^5.1.0 - Environment variable management
- `shared_preferences`: ^2.2.2 - Local data storage

## 📋 Prerequisites

Before running this project, ensure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.9.2 or higher)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- [Firebase CLI](https://firebase.google. com/docs/cli) (for Firebase configuration)
- Android Studio / Xcode (for mobile development)
- A code editor (VS Code, Android Studio, or IntelliJ IDEA)

## 🔧 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/abdulqadir263/fyp_phase1.git
   cd fyp_phase1
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Configuration**
   - Copy the `.env.example` file to `.env`
   ```bash
   cp .env.example .env
   ```
   - Fill in your environment variables in the `.env` file:
     - Firebase configuration keys
     - Cloudinary API credentials
     - Google AI API keys
     - Any other required API keys

4. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication and Cloud Firestore
   - Download and place configuration files:
     - `google-services.json` for Android (in `android/app/`)
     - `GoogleService-Info.plist` for iOS (in `ios/Runner/`)

5. **Run the application**
   ```bash
   # Run on connected device
   flutter run
   
   # Run on specific platform
   flutter run -d chrome        # Web
   flutter run -d android       # Android
   flutter run -d ios           # iOS
   ```

## 🔐 Security Notes

- Never commit your `. env` file or Firebase configuration files with sensitive data
- Keep your API keys secure and rotate them regularly
- Enable appropriate Firebase security rules for production
- Use environment-specific configurations for development and production

## 🧪 Testing

Run the test suite with:

```bash
flutter test
```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🤝 Contributing

This is a Final Year Project repository. If you'd like to contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is part of an academic Final Year Project.  All rights reserved.

## 👤 Author

**Abdul Qadir**
- GitHub: [@abdulqadir263](https://github.com/abdulqadir263)

## 📧 Contact

For questions or support regarding this project, please open an issue in the GitHub repository.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- All open-source contributors whose packages made this project possible

---

**Note**: This is Phase 1 of the Final Year Project. Additional features and improvements are planned for subsequent phases. 
