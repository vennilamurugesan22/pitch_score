# Live-link hosting (Firebase Hosting)

Makes shared links like `https://pitchscore-d15a6.web.app/watch/123456` open the app.

## Deploy (one time, and after any change here)
```bash
firebase login --reauth
firebase deploy --only hosting
```
Check: https://pitchscore-d15a6.web.app/.well-known/assetlinks.json must return the JSON.

## Before Play Store release
`assetlinks.json` currently holds the **debug** signing key. Add the SHA-256 of
- your upload/release keystore: `keytool -list -v -keystore <your.jks> -alias <alias>`
- the Play App Signing key: Play Console → Setup → App integrity

…and update `package_name` if you change the applicationId. Redeploy.

## What happens when someone taps the link
- App installed + links verified → app opens straight on Watch Live for that code
- Otherwise the page opens: on Android it launches the app (or Play Store), and shows the live score in the browser.
