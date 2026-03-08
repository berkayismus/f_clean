# F-Clean — Architecture & Development Guide

This document is written to help new engineers quickly adopt the project standards. The project is a Flutter SaaS MVP built with **Clean Architecture**, **BLoC/Cubit**, **GoRouter**, **Dio**, and **injectable**.

---

## Table of Contents

1. [Tech Stack](#1-tech-stack)
2. [Folder and File Structure](#2-folder-and-file-structure)
3. [Clean Architecture Layers](#3-clean-architecture-layers)
4. [Adding a New Feature](#4-adding-a-new-feature)
5. [Dependency Injection (DI)](#5-dependency-injection-di)
6. [BLoC / Cubit Rules](#6-bloc--cubit-rules)
7. [Error Handling](#7-error-handling)
8. [API Layer](#8-api-layer)
9. [Routing](#9-routing)
10. [Localization (slang)](#10-localization-slang)
11. [Theming](#11-theming)
12. [Environment Variables](#12-environment-variables)
13. [Writing Tests](#13-writing-tests)
14. [Code Style & Linting](#14-code-style--linting)
15. [Common Commands](#15-common-commands)
16. [Naming Conventions Summary](#16-naming-conventions-summary)

---

## 1. Tech Stack

| Category | Package | Purpose |
|---|---|---|
| State Management | `flutter_bloc` | BLoC and Cubit |
| DI | `injectable` + `get_it` | Dependency injection |
| Network | `dio` + `pretty_dio_logger` | HTTP client |
| Navigation | `go_router` | Declarative routing |
| Local Storage | `flutter_secure_storage` | Token storage |
| Local Storage | `shared_preferences` | Key-value persistence |
| Functional | `dartz` | `Either<Failure, T>` return type |
| Models | `freezed` + `json_annotation` | Immutable model classes |
| Localization | `slang` + `slang_flutter` | Type-safe i18n |
| Theming | `flex_color_scheme` | Material 3 theme system |
| Environment | `envied` | Secure `.env` file reading |
| Push Notifications | `flutter_local_notifications` | Local notifications |
| Testing | `bloc_test` + `mocktail` | BLoC/Cubit unit tests |

---

## 2. Folder and File Structure

### General Rules

- All **file and folder names** use `snake_case`
- All **class names** use `PascalCase`
- Code generation outputs (`*.freezed.dart`, `*.g.dart`) must never be edited manually

### Lib Tree

```
lib/
├── main.dart                  # Application entry point
├── app.dart                   # MaterialApp.router, theme, localization
├── core/
│   ├── api/                   # Dio client, interceptors, token storage
│   ├── di/                    # GetIt setup, CoreModule, injection.config.dart (generated)
│   ├── env/                   # DevEnv, ProdEnv, AppConfig
│   ├── error/                 # Exception and Failure classes
│   ├── l10n/                  # Slang JSON source files and generated strings
│   ├── notifications/         # NotificationService
│   ├── router/                # GoRouter and AppRoutes constants
│   ├── theme/                 # AppTheme, AppThemeExtension
│   └── utils/                 # AppConstants, extensions
└── features/
    └── <feature>/
        ├── data/
        │   ├── datasources/   # Abstract + impl (same file)
        │   ├── models/        # Freezed models, .toEntity() method
        │   └── repositories/  # RepositoryImpl
        ├── domain/
        │   ├── entities/      # Pure Dart classes, Equatable
        │   ├── repositories/  # Abstract repository interfaces
        │   └── usecases/      # One class per use case
        └── presentation/
            ├── bloc/          # XBloc, XEvent, XState (or cubit/)
            ├── pages/         # XPage (provides BLoC), _XView (consumes BLoC)
            └── widgets/       # Sub-widgets
```

> **Exception:** Features that manage pure UI state (e.g. `settings`) only have a `presentation/` layer — no `data/` or `domain/` needed.

---

## 3. Clean Architecture Layers

### Domain Layer — Business Logic

**Independent** of Flutter and third-party libraries. Contains pure Dart only.

| File Type | Rules |
|---|---|
| **Entity** | Extends `Equatable`, `@immutable`, no `import 'package:dio/...'` |
| **Repository Interface** | `abstract class XRepository`, all methods return `Future<Either<Failure, T>>` |
| **Use Case** | `@injectable`, single `call(XParams params)` method, only injects a repository |

```dart
// ✅ Correct — domain/usecases/login_usecase.dart
@injectable
class LoginUseCase {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call(LoginParams params) =>
      _repository.login(email: params.email, password: params.password);
}
```

### Data Layer — Data Sources

Network calls, local storage, and platform APIs are handled here.

| File Type | Rules |
|---|---|
| **Model** | `@freezed`, `fromJson` factory, `toEntity()` method is mandatory |
| **DataSource** | Abstract class and impl in the **same file**; impl catches `DioException` and throws domain exceptions |
| **RepositoryImpl** | `@Injectable(as: XRepository)`, try/catch → `Left(Failure)` / `Right(data)` |

```dart
// ✅ Correct — data/models/user_model.dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({required String id, required String email}) = _UserModel;
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}

extension UserModelX on UserModel {
  UserEntity toEntity() => UserEntity(id: id, email: email);
}
```

### Presentation Layer — UI

BLoC/Cubit and widgets live here. Injects domain use cases; never accesses repositories directly.

**Page → View split:**
- `XPage` — creates the BLoC (`BlocProvider`) and returns `_XView`. Contains no business logic.
- `_XView` (private) — uses `BlocListener` + `BlocBuilder`, dispatches events.

```dart
// ✅ Correct — presentation/pages/login_page.dart
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(const AppStarted()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget { ... }
```

---

## 4. Adding a New Feature

Follow these steps in order when adding a new feature (e.g. `products`):

### Step 1 — Create the Domain layer

```
lib/features/products/domain/
  entities/product_entity.dart              # Equatable, immutable
  repositories/product_repository.dart      # abstract, returns Either
  usecases/get_products_usecase.dart
  usecases/get_product_detail_usecase.dart
```

### Step 2 — Create the Data layer

```
lib/features/products/data/
  models/product_model.dart                           # @freezed, fromJson, toEntity()
  datasources/product_remote_datasource.dart          # abstract + impl in same file
  repositories/product_repository_impl.dart           # @Injectable(as: ProductRepository)
```

### Step 3 — Add DI annotations

```dart
// DataSource impl
@Injectable(as: ProductRemoteDataSource)
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource { ... }

// Repository impl
@Injectable(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository { ... }

// Use case (factory — new instance each time)
@injectable
class GetProductsUseCase { ... }

// BLoC (factory — managed by BlocProvider)
@injectable
class ProductBloc extends Bloc<ProductEvent, ProductState> { ... }
```

Then regenerate the code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Step 4 — Create the Presentation layer

```
lib/features/products/presentation/
  bloc/product_bloc.dart
  bloc/product_event.dart
  bloc/product_state.dart
  pages/products_page.dart    # BlocProvider + _ProductsView
  widgets/product_card.dart
```

### Step 5 — Add a route

Add constants in `lib/core/router/app_routes.dart`:

```dart
static const products     = '/products';
static const productsName = 'products';
```

Add the `GoRoute` in `lib/core/router/app_router.dart`:

```dart
GoRoute(
  path: AppRoutes.products,
  name: AppRoutes.productsName,
  builder: (context, state) => const ProductsPage(),
),
```

### Step 6 — Add localization keys

Add the new section to both `lib/core/l10n/en.i18n.json` and `tr.i18n.json`:

```json
{
  "products": {
    "title": "Products",
    "empty": "No products found."
  }
}
```

Then rebuild:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Step 7 — Write tests

```
test/unit/products/
  product_bloc_test.dart
```

---

## 5. Dependency Injection (DI)

### Choosing a Scope

| Annotation | When to Use | Examples |
|---|---|---|
| `@singleton` | One instance is sufficient for the entire app lifetime | `ApiClient`, `TokenStorage`, `SettingsCubit`, `NotificationService` |
| `@injectable` | A fresh instance is needed at each injection point | `AuthBloc`, use cases, datasource and repo impls |
| `@preResolve @singleton` | Must be resolved asynchronously before app starts | `SharedPreferences` |
| `@module` | Third-party / platform deps that cannot be annotated | `FlutterSecureStorage`, `FlutterLocalNotificationsPlugin` |
| `@Injectable(as: Interface)` | Impl classes that have an interface | `AuthRepositoryImpl`, `AuthRemoteDataSourceImpl` |

### Using `@module`

Third-party classes that cannot be annotated go in `lib/core/di/core_module.dart`:

```dart
@module
abstract class CoreModule {
  @singleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @preResolve
  @singleton
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @singleton
  FlutterLocalNotificationsPlugin get localNotifications =>
      FlutterLocalNotificationsPlugin();
}
```

### Code Generation

Must be run **every time** a DI annotation is added or changed:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Never manually edit `lib/core/di/injection.config.dart`.

### Providing BLoC

```dart
// Factory BLoC — new instance per page
BlocProvider(
  create: (_) => getIt<AuthBloc>()..add(const AppStarted()),
  child: const _LoginView(),
)

// Singleton Cubit — share the existing instance
BlocProvider.value(
  value: getIt<SettingsCubit>(),
  child: ...,
)
```

---

## 6. BLoC / Cubit Rules

### BLoC or Cubit?

| Situation | Preference |
|---|---|
| Network calls, use case integration, complex flows | **BLoC** |
| Simple UI state (theme, locale, form values) | **Cubit** |

### Event Naming

Event names must follow a **verb phrase** format:

```dart
// ✅ Correct
class LoginRequested extends AuthEvent { ... }
class AppStarted extends AuthEvent { ... }
class LogoutRequested extends AuthEvent { ... }

// ❌ Wrong
class Login extends AuthEvent { ... }
class AuthLogin extends AuthEvent { ... }
```

### State Naming

```dart
abstract class AuthState extends Equatable { ... }

class AuthInitial extends AuthState { ... }
class AuthLoading extends AuthState { ... }
class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
  ...
}
class AuthUnauthenticated extends AuthState { ... }
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  ...
}
```

### BLoC Handler Pattern

```dart
on<LoginRequested>(_onLoginRequested);

Future<void> _onLoginRequested(
  LoginRequested event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthLoading());
  final result = await _loginUseCase(
    LoginParams(email: event.email, password: event.password),
  );
  result.fold(
    (failure) => emit(AuthError(failure.message)),
    (user)    => emit(AuthAuthenticated(user)),
  );
}
```

### BlocListener vs BlocBuilder

- `BlocListener` → side effects (navigation, snackbar, dialog)
- `BlocBuilder` → UI rebuilds
- Use `BlocConsumer` when both are needed simultaneously

---

## 7. Error Handling

### Flow

```
DataSource            RepositoryImpl           BLoC
    │                      │                    │
    │  throws DioException  │                    │
    │──────────────────────>│                    │
    │                       │ catch → Left(      │
    │                       │  ServerFailure)    │
    │                       │───────────────────>│
    │                       │                    │  result.fold(
    │                       │                    │    (f) => emit(AuthError)
    │                       │                    │    (u) => emit(AuthAuthenticated)
    │                       │                    │  )
```

### Exception Types (`lib/core/error/exceptions.dart`)

```dart
ServerException(message, {statusCode})   // HTTP 4xx/5xx
NetworkException([message])              // Connectivity error
CacheException([message])                // Local storage error
UnauthorizedException([message])         // 401
```

### Failure Types (`lib/core/error/failures.dart`)

```dart
ServerFailure(message, {statusCode})
NetworkFailure([message])
CacheFailure([message])
UnauthorizedFailure([message])
UnknownFailure([message])
```

### RepositoryImpl Pattern

```dart
@override
Future<Either<Failure, UserEntity>> login({
  required String email,
  required String password,
}) async {
  try {
    final result = await _dataSource.login(email: email, password: password);
    return Right(result.user.toEntity());
  } on UnauthorizedException catch (e) {
    return Left(UnauthorizedFailure(e.message));
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(UnknownFailure(e.toString()));
  }
}
```

---

## 8. API Layer

### ApiClient

`lib/core/api/api_client.dart` — `@singleton`. A `Dio` wrapper configured with `BaseOptions` (baseUrl, timeouts, content-type), `AuthInterceptor`, and `PrettyDioLogger`.

The base URL comes from `AppConfig.apiBaseUrl` (see [§12 Environment Variables](#12-environment-variables)).

### Token Refresh

`AuthInterceptor` (`QueuedInterceptorsWrapper`) — on a 401 response, calls `/auth/refresh`, then retries the original request. On refresh failure, tokens are cleared.

### DataSource Call Pattern

```dart
Future<UserModel> getProfile() async {
  try {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/users/me');
    return UserModel.fromJson(response.data!);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) throw const UnauthorizedException();
    throw ServerException(
      e.message ?? 'Server error',
      statusCode: e.response?.statusCode,
    );
  }
}
```

---

## 9. Routing

### Route Constants

All path and name constants are kept in the `AppRoutes` abstract class in `lib/core/router/app_routes.dart`:

```dart
abstract class AppRoutes {
  static const login         = '/login';
  static const loginName     = 'login';
  static const dashboard     = '/';
  static const dashboardName = 'dashboard';
}
```

### Navigation

```dart
// Replace current page (removes from back stack)
context.goNamed(AppRoutes.dashboardName);

// Push onto stack (back button works)
context.pushNamed(AppRoutes.settingsName);

// With path parameters
context.goNamed('resetPassword', pathParameters: {'token': token});
```

### Global Redirect (Auth Guard)

The `_globalRedirect` function in `app_router.dart` checks `TokenStorage.hasAccessToken()` before every navigation:

- Not authenticated + not on login page → `/login`
- Authenticated + on login page → `/`

---

## 10. Localization (slang)

### Source Files

`lib/core/l10n/en.i18n.json` and `tr.i18n.json` — English is the base locale, Turkish is the translation.

### Using Translations

```dart
// String access
Text(context.t.auth.loginButton)

// Parameterized string
Text(context.t.dashboard.welcome(name: user.name))
```

> `context.t` is the extension provided by `lib/core/l10n/strings.g.dart`.

### Adding New Keys

1. Add the same structure to both JSON files
2. Run `dart run build_runner build --delete-conflicting-outputs`
3. Type-safe accessors are generated automatically

### Changing Locale

`SettingsCubit.setLocale(locale)` → `BlocConsumer` in `app.dart` → `LocaleSettings.setLocale(...)` → persisted to `SharedPreferences`.

---

## 11. Theming

### Usage

```dart
// Spacing/radius/colors from AppThemeExtension
final ext = Theme.of(context).extension<AppThemeExtension>()!;
SizedBox(height: ext.spacingMd)   // 16
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(ext.radiusMd),
  ),
)

// Context extensions (lib/core/utils/extensions.dart)
context.colorScheme.primary
context.textTheme.titleLarge
context.isDarkMode
```

### Modifying the Theme

- Color scheme: `lib/core/theme/app_theme.dart` → change `FlexScheme.xxx`
- Custom tokens: `lib/core/theme/app_theme_extension.dart` → add fields to `AppThemeExtension`, update `copyWith` and `lerp`

---

## 12. Environment Variables

### File Structure

```
.env.dev    # Development environment (never committed to git)
.env.prod   # Production environment (never committed to git)
```

Example `.env` file content:

```
API_BASE_URL=https://api.dev.example.com
SENTRY_DSN=https://xxx@sentry.io/yyy
```

### How It Works

1. `envied_generator` reads the `.env` files and generates `lib/core/env/env.g.dart` (obfuscated)
2. `AppConfig.apiBaseUrl` → `kReleaseMode ? ProdEnv.apiBaseUrl : DevEnv.apiBaseUrl`
3. To regenerate: `dart run build_runner build --delete-conflicting-outputs`

> `.env` files must never be added to version control. Make sure they are in `.gitignore`.

---

## 13. Writing Tests

### Folder Structure

```
test/
└── unit/
    └── <feature>/
        └── <feature>_bloc_test.dart
        └── <feature>_cubit_test.dart
```

### Defining Mocks (mocktail)

```dart
class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
```

### Registering Fallback Values

`registerFallbackValue` must be called in `setUpAll` for value-type parameters used with `any()`:

```dart
setUpAll(() {
  registerFallbackValue(const LoginParams(email: 'a@b.com', password: '1234'));
});
```

### Test Structure

```dart
group('AuthBloc', () {
  late MockLoginUseCase mockLoginUseCase;
  late AuthBloc sut;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    sut = AuthBloc(
      loginUseCase: mockLoginUseCase,
      logoutUseCase: mockLogoutUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
    );
  });

  tearDown(() => sut.close());

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthAuthenticated] when login succeeds',
    build: () {
      when(() => mockLoginUseCase(any()))
          .thenAnswer((_) async => Right(tUser));
      return sut;
    },
    act: (bloc) => bloc.add(
      const LoginRequested(email: 'test@test.com', password: '123456'),
    ),
    expect: () => [
      const AuthLoading(),
      AuthAuthenticated(tUser),
    ],
  );
});
```

### Cubit Tests

```dart
test('initial state should contain ThemeMode.system', () {
  when(() => mockPrefs.getString(any())).thenReturn(null);
  when(() => mockPrefs.getBool(any())).thenReturn(null);

  final cubit = SettingsCubit(mockPrefs);

  expect(cubit.state.themeMode, ThemeMode.system);
});
```

### What to Test

- ✅ BLoC and Cubit — all event/state transitions
- ✅ Use cases — with mocked repositories
- ✅ Repository impls — with mocked datasources
- ❌ `*.g.dart`, `*.freezed.dart`, `injection.config.dart` — never test generated files
- ❌ Widget tests — excluded; `test/widget_test.dart` is a placeholder only

---

## 14. Code Style & Linting

### Base Rule

`analysis_options.yaml` extends `package:flutter_lints/flutter.yaml`.

### Strict Analyzer Settings

```yaml
analyzer:
  language:
    strict-casts: true       # No implicit casts allowed
    strict-inference: true   # Type inference must be explicit
    strict-raw-types: true   # Raw generics are forbidden
```

### Active Linter Rules (key ones)

| Rule | Description |
|---|---|
| `always_declare_return_types` | Return types must always be declared |
| `prefer_single_quotes` | Use `'` for strings |
| `prefer_const_constructors` | Use `const` constructors wherever possible |
| `prefer_final_fields` | Fields that don't change must be `final` |
| `prefer_final_locals` | Local variables that don't change must be `final` |
| `avoid_print` | Use proper logging instead of `print()` |
| `use_key_in_widget_constructors` | `key` parameter is required in widgets |
| `directives_ordering` | Import order: dart → flutter → packages → project |

### Analyzer Exclusions

```yaml
exclude:
  - '**/*.g.dart'
  - '**/*.freezed.dart'
  - 'lib/core/di/injection.config.dart'
  - 'lib/core/l10n/strings.g.dart'
```

---

## 15. Common Commands

```bash
# Install dependencies
flutter pub get

# Code generation (Freezed, injectable, slang, envied)
dart run build_runner build --delete-conflicting-outputs

# Code generation (watch mode — use during development)
dart run build_runner watch --delete-conflicting-outputs

# Run all tests
flutter test

# Run a single test file
flutter test test/unit/auth/auth_bloc_test.dart

# Coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run in development environment
flutter run

# Static analysis
flutter analyze

# Auto-fix lint issues
dart fix --apply
```

---

## 16. Naming Conventions Summary

| Artifact | Convention | Example |
|---|---|---|
| Entity | `XEntity` | `UserEntity` |
| Model | `XModel` | `UserModel`, `TokenModel` |
| Model extension | `XModelX` | `UserModelX` |
| Repository (abstract) | `XRepository` | `AuthRepository` |
| Repository impl | `XRepositoryImpl` | `AuthRepositoryImpl` |
| DataSource (abstract) | `XDataSource` | `AuthRemoteDataSource` |
| DataSource impl | `XDataSourceImpl` | `AuthRemoteDataSourceImpl` |
| Use Case | `XUseCase` | `LoginUseCase`, `GetCurrentUserUseCase` |
| Use Case params | `XParams` | `LoginParams` |
| BLoC | `XBloc` | `AuthBloc` |
| Event (abstract) | `XEvent` | `AuthEvent` |
| Event (concrete) | verb phrase | `LoginRequested`, `AppStarted` |
| State (abstract) | `XState` | `AuthState` |
| State (concrete) | `X + status` | `AuthLoading`, `AuthAuthenticated` |
| Cubit | `XCubit` | `SettingsCubit` |
| Cubit State | `XState` | `SettingsState` |
| Page | `XPage` | `LoginPage`, `DashboardPage` |
| Private view | `_XView` | `_LoginView` |
| Widget | descriptive name | `LoginForm`, `ProductCard` |
| DI Module | `XModule` | `CoreModule` |
| Router | `AppRouter`, `AppRoutes` | — |
| Extensions | `XExtension` or `ContextX` | `AppThemeExtension`, `ContextX` |
| Constants | `AppConstants` | — |
| Config | `AppConfig` | — |
| Env | `DevEnv`, `ProdEnv` | — |
