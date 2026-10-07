# CityCare

Patient app for **finding clinics, booking appointments and tracking queue tokens**. It's a standalone Flutter project, and the only thing it shares with RemindMe is the backend. It imports none of RemindMe's code.

```
Splash → Continue with Google → Home → Find healthcare → Clinic → Doctor
  → Appointment type → Date → Time → Confirm → Confirmed
  → My appointments → Appointment details → Live queue / token
```

## Run

```bash
flutter pub get
flutter run                                   # production backend
flutter run --dart-define=CLINIC_API_BASE_URL=http://10.0.2.2:3100/api   # local platform
```

| dart-define | Default |
|---|---|
| `CLINIC_API_BASE_URL` | `https://remind-me-indol.vercel.app/api` |
| `GOOGLE_SERVER_CLIENT_ID` | The platform's OAuth *web* client ID (the audience `/api/auth/google/verify` accepts) |

The app holds no secrets. Client IDs are public, and the database URL, client secret and server keys stay on the backend.

## One-time Google Sign-In setup

Google Sign-In on Android only works once the package and signing key are registered. In Google Cloud project **883368917967** (the one that owns the web client above), go to **APIs & Services → Credentials → Create OAuth client ID → Android**:

| Field | Value |
|---|---|
| Package name | `com.family.clinic_app` |
| SHA-1 (debug) | `B4:63:64:6E:42:40:0C:64:3F:8F:55:E1:1D:F7:58:ED:FE:2D:16:80` |

Add the release keystore's SHA-1 as well before shipping. You don't need a `google-services.json`, and the backend needs no changes: the ID token's audience is the web client ID, which `verifyIdToken` already accepts.

**iOS:** create an iOS OAuth client, then add `GIDClientID` and the reversed-client-ID URL scheme to `ios/Runner/Info.plist`.

## Features

- Continue with Google, or browse as a guest. Booking asks guests to sign in.
- Search clinics and doctors with filters: **Near me**, city, clinic type and specialty.
- Book a timed slot or a same-day token, for **yourself or a family member**.
- **Change the time** of an appointment, or cancel it.
- Live queue and token status.
- **Visit summary and prescriptions** after a visit, plus a **My prescriptions** list.
- **Notification inbox** with an unread badge, and **push notifications** for bookings, reminders and "it's your turn".
- One-tap **Call**, **Directions**, **Email**, **Website** and **Add to calendar**.

## One-time setup for push, reminders and demo data

1. **Firebase app config:** put `google-services.json` (Firebase project `remind-me-b7830`, app `com.family.clinic_app`) at `android/app/google-services.json`. It is gitignored.
2. **Backend push key:** in Firebase, go to **Project settings → Service accounts → Generate new private key**. Put the JSON, or its base64 encoding, into the Vercel env var `FCM_SERVICE_ACCOUNT_JSON`, then redeploy.
3. **Database migration:** the backend's `vercel-build` script runs `prisma migrate deploy`, so Vercel needs `DIRECT_URL` (the non-pooled Neon URL) in its env vars.
4. **Scheduled reminders:** the 24 h and 2 h reminders are delivered by `POST /api/internal/notifications/dispatch` with the header `X-Cron-Key: <NOTIFICATIONS_CRON_SECRET>`. Call it every 5 minutes from an external scheduler such as cron-job.org, because Vercel Hobby crons run only once a day. Immediate events (booked, cancelled, queue called) push instantly without this.
5. **Demo clinics** (fictional, marked "(Demo)"): run `SEED_ADMIN_PASSWORD='...' python platform/scripts/seed_demo_clinics.py` after the backend deploy.

## Architecture

```
lib/
  main.dart                 bootstraps; starts session restore before first frame
  app/                      app.dart (providers), router.dart (go_router + auth guard),
                            theme.dart (Clinic design tokens), dependencies.dart
  core/
    auth/                   AuthController (the single auth state), GoogleAuthGateway, AppUser
    network/                ApiClient (auth interceptor, single-flight refresh), Paged
    storage/                TokenStorage (secure storage for the platform session)
    errors/                 ApiException + friendlyMessage (no technical errors reach patients)
    widgets/                skeletons, empty/error views, AsyncView, PagedList
    utils/                  ClinicTime (times in the clinic's IANA zone), JSON readers
  features/
    auth/ home/ profile/
    clinics/    data/ (models, ClinicRepository) + presentation/
    doctors/    data/ (models, DoctorRepository) + presentation/
    appointments/ data/ (models, AppointmentRepository) + booking flow + lists
    queue/      data/ (models, QueueRepository) + token + live queue
  shared/app_shell.dart     bottom navigation: Home · Appointments · Find · Profile
```

### Authentication

1. `GoogleSignIn(serverClientId: web client)` returns a Google ID token.
2. `POST /api/auth/google/verify` with `X-Client: app` returns `{ accessToken, refreshToken }`. The backend finds the user by Google `sub`, or by verified email, or creates one.
3. The session is stored in `flutter_secure_storage`, then `GET /api/me` loads the profile.
4. Every protected call sends `Authorization: Bearer`. A 401 triggers one shared refresh (`/api/auth/refresh`) and then replays the request. If the server rejects the refresh, the app signs out. If the refresh fails because the device is offline, the session is kept.
5. On launch the splash stays up until the session is restored, so a signed-in patient never sees the login screen.
6. Logout revokes the refresh token on the server, clears local storage and signs out of Google.

### Backend APIs used

| Purpose | Endpoint |
|---|---|
| Sign in | `POST /api/auth/google/verify`, `POST /api/auth/refresh`, `POST /api/auth/logout`, `GET /api/me` |
| Clinics | `GET /api/public/organizations?q&page&pageSize`, `GET /api/public/organizations/:slug` |
| Doctors | `GET /api/public/doctors?q`, `GET /api/public/doctors/:id` |
| Availability | `GET /api/public/doctors/:id/slots?date&appointmentTypeId` |
| Book | `POST /api/patient/appointments` |
| My appointments | `GET /api/orgs` (PATIENT memberships), `GET /api/orgs/:orgId/appointments`, `GET …/appointments/:id`, `POST …/appointments/:id/cancel` |
| Family | `GET /api/patient/family?organizationId` |
| Reschedule | `POST /api/orgs/:orgId/appointments/:id/reschedule` |
| Records | `GET …/appointments/:id/consultation`, `GET /api/orgs/:orgId/prescriptions` |
| Notifications | `GET /api/orgs/:orgId/notifications`, `POST …/notifications/read` |
| Push | `POST` / `DELETE /api/me/devices` |
| Filters | `GET /api/public/filters`, `GET /api/public/organizations?lat&lng&city&orgType` |
| Tokens / queue | `GET /api/public/doctors/:id/token-window`, `POST /api/patient/appointments/token`, `GET /api/patient/token-status?appointmentId` |

The app never computes slots, queue positions or fees. All of them come from the backend.

## Tests

```bash
flutter test                                        # unit + widget (offline, fixtures from production)
flutter test test/smoke --dart-define=SMOKE=true    # read-only live smoke test
# include authenticated checks with a session from a real Google sign-in:
flutter test test/smoke --dart-define=SMOKE=true \
  --dart-define=SMOKE_ACCESS_TOKEN=... --dart-define=SMOKE_REFRESH_TOKEN=...
```
