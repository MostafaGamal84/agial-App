# Ajyal Al-Quran – Mobile Reports (Flutter)

This Flutter app demonstrates the Ajyal Al-Quran mobile experience for logging in with phone/email, confirming OTP, viewing role-filtered circle reports, and adding or editing reports with the same hierarchy logic used on the web app.

## Mock credentials
Use one of the built-in accounts to explore the role-specific flows:

| Role | Login value |
| --- | --- |
| Admin | `admin@example.com` |
| Branch Leader | `branch@example.com` |
| Supervisor | `manager@example.com` |
| Teacher | `teacher@example.com` |

Any password is accepted. The OTP for all accounts is `123456`.

## Running locally
1. Ensure Flutter (stable) is installed.
2. Get packages:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Highlights
- Login + OTP confirmation mirrors `/api/Account/Login` + `/api/Account/VerifyCode`.
- Role-based dropdown chaining for supervisor → teacher → circle → student on add/edit forms.
- Attendance logic drives conditional required fields for minutes and memorization sections.
- Filterable reports list that respects the current user's scope.

The app uses in-memory seed data to mimic backend responses; hook up the service layer to real APIs when ready.
