💬 Chat App
<img src="assets/launcher_icon.png" width="100" alt="App Icon"/>

A modern real-time chat application built with Flutter and Firebase, featuring:

User authentication (Sign Up & Login)

Real-time messaging using Cloud Firestore

Media sharing (images, audio recordings)

Profile photo upload via Cloudinary

Push notifications for new messages using Firebase Cloud Messaging (FCM)

Local notifications for foreground message alerts

🚀 Features

User Authentication

Secure sign up and login with Firebase Authentication.

Persistent user sessions.

Real-time Chat

One-to-one chat between authenticated users.

Live updates using Firestore’s snapshot streams.

Message types: text, image, and audio.

Media Upload

Image uploads via Cloudinary.

Audio messages recorded and uploaded automatically.

Downloads with permission handling on Android/iOS.

Push Notifications

Firebase Cloud Messaging integrated.

Local notifications shown when app is open.

Cloud Function / API triggers push messages on new chats.

Profile Management

Upload and update profile photos.

Automatic FCM token updates for each logged-in user.

🧩 Tech Stack
Layer	Technology
Frontend	Flutter (Dart)
Backend	Firebase (Auth, Firestore, Cloud Messaging)
Media Hosting	Cloudinary
Notifications	FCM + flutter_local_notifications
Permissions	permission_handler
Image Picker	image_picker
Audio Recorder	record
State Management	Provider



⚙️ Setup Instructions
1. Clone the Repository
git clone https://github.com/yourusername/chat_app.git
cd chat_app

2. Install Dependencies
flutter pub get

3. Configure Firebase

Create a new Firebase project at Firebase Console
.

Add your Android and/or iOS app.

Download the configuration files:

google-services.json → android/app/

GoogleService-Info.plist → ios/Runner/

Run Firebase CLI setup:

flutterfire configure

4. Enable Firebase Services

In your Firebase project, enable:

Authentication → Email/Password

Cloud Firestore

Cloud Messaging

5. Configure Cloudinary

Create an account at Cloudinary
.

Note your Cloud Name and Upload Presets.

Update them in your image upload methods inside:

uploadImageToCloudinary()

6. Add Google Service Account (optional for FCM v1 API)

If you use server-side FCM (Service Account JSON):

Place your file in assets/data/data_key_cloud_console.json

Update the path in your sendPushMessage() function.



7. Run the App
flutter run

🔔 Push Notification Flow

Each user’s FCM token is saved in their Firestore document (userDetails/{uid}).

When one user sends a message:

The app fetches the recipient’s token.

It triggers a push notification using FCM (either via REST API or service account).

On the receiver’s device:

If the app is open → local notification displayed.

If backgrounded → system notification shown.

🧠 Key Classes
File	Responsibility
firebase_api.dart	Handles FCM permissions and token registration.
chat_provider.dart	Sends messages and triggers FCM push notifications.
profile_update_page_provider.dart	Manages profile image and FCM token updates.
noti_service.dart	Displays local notifications using flutter_local_notifications.
🔒 Security Notes

Do not include your Firebase Server Key or Service Account JSON in public repositories.

Restrict Firestore rules to authenticated users.

For production, move push notification sending logic to a secure backend or Firebase Cloud Function.

💡 Future Enhancements

Group chat support

Typing indicators

Message read receipts

End-to-end encryption

Message reactions

Push-to-talk with waveform visualization

🧑‍💻 Author

Jerin John
💼 Flutter Developer
📧 your.email@example.com