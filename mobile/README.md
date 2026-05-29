# Rezumate Mobile

Expo client for the FastAPI Rezumate backend.

## Run Locally

```bash
cd mobile
npm install
npm run ios
```

Set `EXPO_PUBLIC_API_BASE_URL` in `mobile/.env`.

Simulator URLs:

- iOS simulator with backend on the same Mac: `http://127.0.0.1:8000`
- Android emulator with backend on the host Mac: `http://10.0.2.2:8000`
- Physical phone: use your Mac LAN IP, for example `http://192.168.1.20:8000`

The backend currently accepts any non-empty bearer token through its mock auth dependency. `EXPO_PUBLIC_DEV_AUTH_TOKEN=dev-token` is enough until Supabase JWT validation is wired server-side.
