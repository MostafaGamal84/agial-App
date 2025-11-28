# Ajyal Al-Quran – Mobile Reports (Flutter)

This Flutter app mirrors the Ajyal Al-Quran web experience for logging in with phone/email, confirming OTP, viewing role-filtered circle reports, and adding or editing reports using the same backend endpoints.

## Configuration
- Set the API base URL at build time using the `API_BASE_URL` Dart define (defaults to `https://example.com/api`).
  ```bash
  flutter run --dart-define=API_BASE_URL=https://your-domain.com/api
  ```
- All authenticated requests automatically include the JWT returned by `/api/Account/VerifyCode`.

## Running locally
1. Ensure Flutter (stable) is installed.
2. Get packages:
   ```bash
   flutter pub get
   ```
3. Run the app, providing your API base if needed:
   ```bash
   flutter run --dart-define=API_BASE_URL=https://your-domain.com/api
   ```

## Highlights
- Login + OTP confirmation wired to `/api/Account/Login` and `/api/Account/VerifyCode` responses.
- Role-based dropdown chaining (Supervisor → Teacher → Circle → Student) uses `UsersForGroups`, `Circle/GetResultsByFilter`, and `Circle/Get` to mirror web filtering.
- Attendance logic drives conditional required fields for minutes and memorization sections before calling `CircleReport/Create` or `CircleReport/Update`.
- Reports list pulls from `CircleReport/GetResultsByFilter` while enforcing teacher scoping for logged-in teachers.

**Note:** The app now targets real endpoints; provide valid backend credentials and OTP codes from your environment when testing.
