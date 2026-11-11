# Flowa APK and PWA publishing

The `Build Release APK` workflow now has two jobs:

- `build-release`: builds the Android APK, uploads the workflow artifact, and publishes/replaces the `flowa-latest` GitHub Release asset.
- `build-pwa`: generates Flutter's web platform, builds an installable PWA, and deploys it to GitHub Pages under `/Flowa/`.

## One-time Firebase Web setup

The Firebase project currently has an Android app configuration in the repository. A separate Firebase Web app must be registered before the PWA can authenticate or access Firestore.

1. Open Firebase Console > project `flowa-d6d47` > Project settings > Your apps.
2. Add a Web app named `Flowa Web` (no Hosting setup is required).
3. Copy the Web app's App ID. It has a form similar to `1:...:web:...`.
4. In GitHub repository Settings > Secrets and variables > Actions, create repository secret:
   - Name: `FIREBASE_WEB_APP_ID`
   - Value: the exact Firebase Web App ID.
5. In Firebase Authentication > Settings > Authorized domains, add the GitHub Pages hostname used by this repository (normally `gacoan449.github.io`).
6. Ensure GitHub Pages is allowed for this repository. The workflow uses GitHub Actions deployment and requests Pages write + OIDC permissions.

The Web app ID is injected at build time and is not committed as a fabricated value. The existing Android Firebase configuration remains unchanged.

## Published addresses

- PWA: `https://gacoan449.github.io/Flowa/`
- Latest APK: `https://github.com/gacoan449/Flowa/releases/download/flowa-latest/app-release.apk`

The PWA includes a persistent **Download APK** link to the latest release. GitHub Actions must complete successfully before either new published build is considered ready.