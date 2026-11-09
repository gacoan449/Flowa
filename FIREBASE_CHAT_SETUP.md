# Flowa Chat – Firebase deployment

The Flutter chat code and Firebase server triggers are stored in this repository. Push notifications will not be sent until the Firestore rules and Cloud Functions are deployed to the Firebase project.

## 1. Deploy Firestore rules and Cloud Functions

Install Firebase CLI, then run from the repository root:

```bash
npm install -g firebase-tools
firebase login
firebase deploy --project flowa-d6d47 --only firestore:rules,functions
```

Cloud Functions deployment requires the Firebase project to use the **Blaze (pay-as-you-go)** plan and the Cloud Functions/Cloud Build APIs to be enabled. Review Firebase pricing and set budget alerts before upgrading. Do not deploy if you do not accept possible usage charges.

## 2. Cloudinary voice uploads

The app uses the existing unsigned preset `ml_default` and cloud `mgr0ynav`. Image uploads use `image/upload`; voice notes use Cloudinary's `video/upload` resource type for audio playback.

In Cloudinary, confirm that the unsigned preset allows uploads for the video resource type and accepts the M4A audio format. No API Secret belongs in the Flutter app or this repository.

## 3. What the backend triggers do

- `notifyChatMessage`: sends an FCM notification to the other participant when a chat message is created and records a delivered receipt when FCM accepts the send.
- `notifySupportMessage`: notifies admins about a new support message and notifies the customer when support replies.
- FCM device tokens are registered under `users/{uid}/devices/{token}`.

Read receipts are written when the recipient opens the conversation. A single check means sent, two muted checks mean accepted for delivery to a registered device, and two bright blue/cyan checks mean read.

## 4. Security

The Firestore rules keep account documents private, expose only limited `public_profiles` fields to signed-in users, restrict chat messages to participants, and protect reports and blocks. Deploy the rules before testing the new profile, receipt, block, and report behavior.
