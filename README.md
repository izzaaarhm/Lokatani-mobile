# Lokatani Mobile App (Timbangan Sayur)

A Flutter-based mobile application for vegetable weighing and identification. This app allows users to weigh vegetables, identify types of vegetables through machine learning, and track weighing history.

## Features

- **User Authentication**
  - Login and registration with email verification
  - Profile management
  - Password reset functionality
  
- **Vegetable Weighing**
  - Real-time weighing from IoT devices
  - Automatic vegetable type identification using ML
  - Weighing history and tracking
  
- **Dashboard & History**
  - Overview of recent weighing activities
  - Detailed history of all weighing sessions
  - Search and filter capabilities for past records


## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- VS Code
- Firebase account
- Physical device or emulator

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/lokatech-timbangan.git
   cd lokatech-timbangan
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - The project already includes Firebase configuration
   - Make sure to connect the app to your Firebase project if you want to deploy your own instance

4. Run the application:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── config/         # App configuration (themes, etc.)
├── pages/          # UI screens
├── routes/         # App navigation
├── services/       # Business logic and API services
├── widgets/        # Reusable UI components
├── main.dart       # App entry point
└── firebase_options.dart  # Firebase configuration
```

## Dependencies

- `firebase_core`, `firebase_auth`, `cloud_firestore` - Firebase integration
- `http` - API communication
- `flutter_image_compress` - Compresses image
- `image_picker` - Picking images from the image library
- `camera` - Camera functionality

For a complete list of dependencies, see the [`pubspec.yaml`](pubspec.yaml) file.

## API Integration

The app connects to a Flask backend for machine learning functionalities:
- Base URL: `https://flask-backend-207122022079.asia-southeast2.run.app/api`
- Endpoints for vegetable identification and data processing
