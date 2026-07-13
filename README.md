# rahhal_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Security & Configuration

> [!IMPORTANT]
> **Do not commit live Firebase options/keys to public repositories!**
> 
> The file `lib/firebase_options.dart` and sensitive config files (`google-services.json`, `GoogleService-Info.plist`) should not contain production keys in public source control. 
> 
> To configure Firebase for this project:
> 1. Install [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/).
> 2. Run the configuration command to generate/regenerate your local options file:
>    ```bash
>    flutterfire configure
>    ```
> 3. Ensure that App Check and Firestore Security Rules are deployed and configured in the Firebase Console.

## Claude AI Backend Proxy & Fallback Mock Data

> [!NOTE]
> The app config in `lib/core/config/app_config.dart` is set up to communicate with a local/remote backend proxy (e.g. `http://192.168.100.7:3000`) for routing Claude API queries.
> If no backend proxy is running or accessible, the app will automatically fall back to serving high-quality mock data for AI generation, chat history, and suggestions.

## Claude AI Backend Proxy Setup & Run

We have provided a lightweight Node.js Express server (`server.js`) that acts as a local proxy to route AI requests to the Anthropic Claude API.

### Prerequisites
- Node.js (v18+)

### Setup Instructions
1. Navigate to this project root directory and install dependencies:
   ```bash
   npm install
   ```
2. Create a `.env` file from the example:
   ```bash
   copy .env.example .env
   ```
3. Open `.env` and fill in your Anthropic API Key:
   ```env
   ANTHROPIC_API_KEY=your_real_anthropic_api_key
   ```

### Running the Server
Start the backend proxy server:
```bash
npm start
```
By default, the server runs on `http://localhost:3000`. You can configure your computer's local IP inside the Flutter configuration `lib/core/config/app_config.dart` or compile/run the app with:
```bash
flutter run --dart-define=PROXY_BASE_URL=http://192.168.100.7:3000
```
If the server is offline or inaccessible, the app automatically falls back to serving rich mock data.
