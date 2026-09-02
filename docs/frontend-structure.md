# Frontend structure

The Flutter application lives at the repository root and supports Android, iOS, Web, and the generated desktop targets.

- `lib/config`: app flavor and `--dart-define` environment configuration.
- `lib/routes`: GoRouter routes, navigation service, and role-guard preparation.
- `lib/core`: API contracts, constants, errors, device-service abstractions, themes, utilities, and dependency injection.
- `lib/shared`: common models, widgets, dialogs, and responsive layouts.
- `lib/features`: 23 feature-first modules spanning rides, rentals, bookings, payments, users, providers, drivers, and administration.
- `lib/l10n`: English, Kannada, and Hindi localization resources.
- `assets`: registered folders for images, icons, illustrations, animations, fonts, and placeholders.

The application uses `MaterialApp.router`, light/dark Material 3 themes, a home service grid, and a five-tab shell for Home, Bookings, Favourites, Notifications, and Profile. Configure the backend with `--dart-define=API_BASE_URL=http://localhost:3000/api/v1`.

To add a feature, give it its own `data`, `domain`, and `presentation` folders, add its screen route to `lib/routes/app_router.dart`, and keep provider/network implementation behind a service or repository interface. Role checks must use the account's full role collection because one account can hold multiple roles.
