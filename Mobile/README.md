# TaskFlow Mobile

Flutter client using MVVM:
View -> ViewModel -> Repository -> Service -> REST API.

Before running:
1. Start the backend with Docker.
2. On Android emulator use `10.0.2.2:8000`.
3. On a physical device replace `baseUrl` in `lib/services/api_service.dart` with the PC LAN IP.
4. Run `flutter pub get`.
5. Run `flutter run`.

Demo user must first be registered through Swagger:
POST /auth/register
