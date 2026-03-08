# F-Clean — Mimari ve Geliştirme Rehberi

Bu döküman projeye yeni katılan yazılım mühendislerinin standartları hızlıca benimsemesi için hazırlanmıştır. Proje; **Clean Architecture**, **BLoC/Cubit**, **GoRouter**, **Dio** ve **injectable** kullanılarak geliştirilmiş bir Flutter SaaS MVP'sidir.

---

## İçindekiler

1. [Tech Stack](#1-tech-stack)
2. [Klasör ve Dosya Yapısı](#2-klasör-ve-dosya-yapısı)
3. [Clean Architecture Katmanları](#3-clean-architecture-katmanları)
4. [Yeni Feature Ekleme Rehberi](#4-yeni-feature-ekleme-rehberi)
5. [Bağımlılık Yönetimi (DI)](#5-bağımlılık-yönetimi-di)
6. [BLoC / Cubit Kuralları](#6-bloc--cubit-kuralları)
7. [Hata Yönetimi](#7-hata-yönetimi)
8. [API Katmanı](#8-api-katmanı)
9. [Routing](#9-routing)
10. [Lokalizasyon (slang)](#10-lokalizasyon-slang)
11. [Tema](#11-tema)
12. [Çevre Değişkenleri](#12-çevre-değişkenleri)
13. [Test Yazma Kuralları](#13-test-yazma-kuralları)
14. [Kod Stili ve Linting](#14-kod-stili-ve-linting)
15. [Sık Kullanılan Komutlar](#15-sık-kullanılan-komutlar)
16. [İsimlendirme Konvansiyonları Özeti](#16-i̇simlendirme-konvansiyonları-özeti)

---

## 1. Tech Stack

| Kategori | Paket | Amaç |
|---|---|---|
| State Management | `flutter_bloc` | BLoC ve Cubit |
| DI | `injectable` + `get_it` | Bağımlılık enjeksiyonu |
| Network | `dio` + `pretty_dio_logger` | HTTP istemcisi |
| Navigasyon | `go_router` | Declarative routing |
| Local Storage | `flutter_secure_storage` | Token saklama |
| Local Storage | `shared_preferences` | Basit anahtar-değer saklama |
| Fonksiyonel | `dartz` | `Either<Failure, T>` dönüş tipi |
| Modeller | `freezed` + `json_annotation` | Immutable model sınıfları |
| Lokalizasyon | `slang` + `slang_flutter` | Tip güvenli i18n |
| Tema | `flex_color_scheme` | Material 3 tema sistemi |
| Ortam Değişkenleri | `envied` | `.env` dosyalarından güvenli okuma |
| Push Bildirimleri | `flutter_local_notifications` | Yerel bildirimler |
| Test | `bloc_test` + `mocktail` | BLoC/Cubit testleri |

---

## 2. Klasör ve Dosya Yapısı

### Genel Kural

- Tüm **dosya ve klasör isimleri** `snake_case` kullanır
- Tüm **sınıf isimleri** `PascalCase` kullanır
- Code generation çıktıları (`*.freezed.dart`, `*.g.dart`) manuel düzenlenmez

### Lib Ağacı

```
lib/
├── main.dart                  # Uygulama giriş noktası
├── app.dart                   # MaterialApp.router, tema, lokalizasyon
├── core/
│   ├── api/                   # Dio istemcisi, interceptor'lar, token storage
│   ├── di/                    # GetIt kurulumu, CoreModule, injection.config.dart (generated)
│   ├── env/                   # DevEnv, ProdEnv, AppConfig
│   ├── error/                 # Exception ve Failure sınıfları
│   ├── l10n/                  # Slang JSON dosyaları ve generated strings
│   ├── notifications/         # NotificationService
│   ├── router/                # GoRouter ve AppRoutes sabitleri
│   ├── theme/                 # AppTheme, AppThemeExtension
│   └── utils/                 # AppConstants, extensions
└── features/
    └── <feature>/
        ├── data/
        │   ├── datasources/   # Abstract + impl (aynı dosya)
        │   ├── models/        # Freezed modeller, .toEntity() metodu
        │   └── repositories/  # RepositoryImpl
        ├── domain/
        │   ├── entities/      # Saf Dart sınıfları, Equatable
        │   ├── repositories/  # Abstract repository arayüzü
        │   └── usecases/      # Bir use case = bir sınıf
        └── presentation/
            ├── bloc/          # XBloc, XEvent, XState (veya cubit/)
            ├── pages/         # XPage (BLoC sağlar), _XView (BLoC kullanır)
            └── widgets/       # Alt widget'lar
```

> **İstisna:** Saf UI state tutan feature'lar (örn. `settings`) yalnızca `presentation/` katmanına sahiptir; `data/` ve `domain/` katmanlarına gerek yoktur.

---

## 3. Clean Architecture Katmanları

### Domain Katmanı — İş Mantığı

Flutter ve üçüncü taraf kütüphanelerden **bağımsızdır**. Saf Dart içerir.

| Dosya Türü | Kurallar |
|---|---|
| **Entity** | `Equatable` extend eder, `@immutable`, hiçbir `import 'package:dio/...'` içermez |
| **Repository Arayüzü** | `abstract class XRepository`, tüm metotlar `Future<Either<Failure, T>>` döner |
| **Use Case** | `@injectable`, tek metot `call(XParams params)`, yalnızca repository inject alır |

```dart
// ✅ Doğru — domain/usecases/login_usecase.dart
@injectable
class LoginUseCase {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call(LoginParams params) =>
      _repository.login(email: params.email, password: params.password);
}
```

### Data Katmanı — Veri Kaynakları

Network, yerel depolama ve platform API'leri burada ele alınır.

| Dosya Türü | Kurallar |
|---|---|
| **Model** | `@freezed`, `fromJson` factory, `toEntity()` metodu zorunlu |
| **DataSource** | Abstract sınıf ve impl **aynı dosyada**; impl `DioException` yakalar, domain exception fırlatır |
| **RepositoryImpl** | `@Injectable(as: XRepository)`, try/catch → `Left(Failure)` / `Right(data)` |

```dart
// ✅ Doğru — data/models/user_model.dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({required String id, required String email}) = _UserModel;
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}

extension UserModelX on UserModel {
  UserEntity toEntity() => UserEntity(id: id, email: email);
}
```

### Presentation Katmanı — UI

BLoC/Cubit ve widget'lar bu katmanda yer alır. Domain use case'leri inject alır, doğrudan repository'e erişmez.

**Page → View ayrımı:**
- `XPage` — BLoC'u oluşturur (`BlocProvider`) ve `_XView`'ı döner. İş mantığı içermez.
- `_XView` (private) — `BlocListener` + `BlocBuilder` kullanır, olay tetikler.

```dart
// ✅ Doğru — presentation/pages/login_page.dart
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

## 4. Yeni Feature Ekleme Rehberi

Yeni bir feature eklerken (örn. `products`) sırayla takip edilmesi gereken adımlar:

### Adım 1 — Domain katmanını oluştur

```
lib/features/products/domain/
  entities/product_entity.dart      # Equatable, immutable
  repositories/product_repository.dart  # abstract, Either döner
  usecases/get_products_usecase.dart
  usecases/get_product_detail_usecase.dart
```

### Adım 2 — Data katmanını oluştur

```
lib/features/products/data/
  models/product_model.dart          # @freezed, fromJson, toEntity()
  datasources/product_remote_datasource.dart  # abstract + impl aynı dosyada
  repositories/product_repository_impl.dart   # @Injectable(as: ProductRepository)
```

### Adım 3 — DI annotasyonlarını ekle

```dart
// DataSource impl
@Injectable(as: ProductRemoteDataSource)
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource { ... }

// Repository impl
@Injectable(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository { ... }

// Use case (factory — her seferinde yeni instance)
@injectable
class GetProductsUseCase { ... }

// BLoC (factory — BlocProvider tarafından yönetilir)
@injectable
class ProductBloc extends Bloc<ProductEvent, ProductState> { ... }
```

Sonra kodu yeniden oluştur:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Adım 4 — Presentation katmanını oluştur

```
lib/features/products/presentation/
  bloc/product_bloc.dart
  bloc/product_event.dart
  bloc/product_state.dart
  pages/products_page.dart    # BlocProvider + _ProductsView
  widgets/product_card.dart
```

### Adım 5 — Route ekle

`lib/core/router/app_routes.dart` dosyasına sabitleri ekle:

```dart
static const products = '/products';
static const productsName = 'products';
```

`lib/core/router/app_router.dart` dosyasına `GoRoute` ekle:

```dart
GoRoute(
  path: AppRoutes.products,
  name: AppRoutes.productsName,
  builder: (context, state) => const ProductsPage(),
),
```

### Adım 6 — Lokalizasyon anahtarlarını ekle

`lib/core/l10n/en.i18n.json` ve `tr.i18n.json` dosyalarına yeni alan ekle:

```json
{
  "products": {
    "title": "Products",
    "empty": "No products found."
  }
}
```

Sonra slang kodunu yeniden oluştur:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Adım 7 — Testleri yaz

```
test/unit/products/
  product_bloc_test.dart
```

---

## 5. Bağımlılık Yönetimi (DI)

### Scope Seçimi

| Annotation | Ne Zaman Kullanılır | Örnekler |
|---|---|---|
| `@singleton` | Uygulama boyunca tek instance yeterli | `ApiClient`, `TokenStorage`, `SettingsCubit`, `NotificationService` |
| `@injectable` | Her inject noktasında yeni instance gerekir | `AuthBloc`, use case'ler, datasource ve repo impl'leri |
| `@preResolve @singleton` | Async olarak resolve edilmesi gerekenler | `SharedPreferences` |
| `@module` | Üçüncü taraf / platform bağımlılıkları (`new` ile oluşturulamayan yapılar) | `FlutterSecureStorage`, `FlutterLocalNotificationsPlugin` |
| `@Injectable(as: Interface)` | Arayüzü olan impl sınıfları | `AuthRepositoryImpl`, `AuthRemoteDataSourceImpl` |

### `@module` Kullanımı

Annotasyon eklenemeyen 3. parti sınıflar `lib/core/di/core_module.dart` dosyasına eklenir:

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

### Kod Üretimi

DI annotasyonu eklendikten veya değiştirildikten sonra **her zaman** çalıştırılmalıdır:

```bash
dart run build_runner build --delete-conflicting-outputs
```

`lib/core/di/injection.config.dart` dosyasını **manuel düzenleme**.

### BLoC Sağlama

```dart
// Factory BLoC — her sayfada yeni instance
BlocProvider(
  create: (_) => getIt<AuthBloc>()..add(const AppStarted()),
  child: const _LoginView(),
)

// Singleton Cubit — mevcut instance'ı paylaş
BlocProvider.value(
  value: getIt<SettingsCubit>(),
  child: ...,
)
```

---

## 6. BLoC / Cubit Kuralları

### BLoC mu Cubit mi?

| Durum | Tercih |
|---|---|
| Network çağrısı, use case entegrasyonu, karmaşık akış | **BLoC** |
| Basit UI state (tema, dil, form değerleri) | **Cubit** |

### Event İsimlendirme

Event isimleri **fiil cümlesi** biçiminde olmalı:

```dart
// ✅ Doğru
class LoginRequested extends AuthEvent { ... }
class AppStarted extends AuthEvent { ... }
class LogoutRequested extends AuthEvent { ... }

// ❌ Yanlış
class Login extends AuthEvent { ... }
class AuthLogin extends AuthEvent { ... }
```

### State İsimlendirme

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

### BLoC Handler Kalıbı

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

### BlocListener + BlocBuilder Ayrımı

- `BlocListener` → yan etkiler (navigation, snackbar, dialog)
- `BlocBuilder` → UI yeniden oluşturma
- İkisi birlikte gerekirse `BlocConsumer` kullan

---

## 7. Hata Yönetimi

### Akış

```
DataSource            RepositoryImpl           BLoC
    │                      │                    │
    │  DioException fırlatır│                    │
    │──────────────────────>│                    │
    │                       │ catch → Left(      │
    │                       │  ServerFailure)    │
    │                       │───────────────────>│
    │                       │                    │  result.fold(
    │                       │                    │    (f) => emit(AuthError)
    │                       │                    │    (u) => emit(AuthAuthenticated)
    │                       │                    │  )
```

### Exception Türleri (`lib/core/error/exceptions.dart`)

```dart
ServerException(message, {statusCode})   // HTTP 4xx/5xx
NetworkException([message])              // Bağlantı hatası
CacheException([message])                // Yerel depolama hatası
UnauthorizedException([message])         // 401
```

### Failure Türleri (`lib/core/error/failures.dart`)

```dart
ServerFailure(message, {statusCode})
NetworkFailure([message])
CacheFailure([message])
UnauthorizedFailure([message])
UnknownFailure([message])
```

### Repository Impl Kalıbı

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

## 8. API Katmanı

### ApiClient

`lib/core/api/api_client.dart` — `@singleton`. `BaseOptions` (baseUrl, timeout, content-type), `AuthInterceptor` ve `PrettyDioLogger` eklenmiş bir `Dio` wrapper'ıdır.

Taban URL `AppConfig.apiBaseUrl` üzerinden gelir (bkz. [§12 Çevre Değişkenleri](#12-çevre-değişkenleri)).

### Token Yenileme

`AuthInterceptor` (`QueuedInterceptorsWrapper`) — 401 geldiğinde `/auth/refresh` çağrısı yapar, orijinal isteği yeniden dener. Refresh başarısız olursa token'lar temizlenir.

### DataSource Çağrı Kalıbı

```dart
Future<UserModel> getProfile() async {
  try {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/users/me');
    return UserModel.fromJson(response.data!);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) throw const UnauthorizedException();
    throw ServerException(
      e.message ?? 'Sunucu hatası',
      statusCode: e.response?.statusCode,
    );
  }
}
```

---

## 9. Routing

### Route Sabitleri

Tüm path ve name sabitleri `lib/core/router/app_routes.dart` dosyasındaki `AppRoutes` abstract sınıfında tutulur:

```dart
abstract class AppRoutes {
  static const login     = '/login';
  static const loginName = 'login';
  static const dashboard     = '/';
  static const dashboardName = 'dashboard';
}
```

### Navigasyon

```dart
// Mevcut sayfayı değiştir (geri çıkış stack'ten silinir)
context.goNamed(AppRoutes.dashboardName);

// Stack'e ekle (geri butonu çalışır)
context.pushNamed(AppRoutes.settingsName);

// Path parametresi ile
context.goNamed('resetPassword', pathParameters: {'token': token});
```

### Global Redirect (Auth Guard)

`app_router.dart` içindeki `_globalRedirect` fonksiyonu, her navigasyon öncesinde `TokenStorage.hasAccessToken()` kontrol eder:

- Oturum açık değil + login sayfasında değilse → `/login`
- Oturum açık + login sayfasındaysa → `/`

---

## 10. Lokalizasyon (slang)

### Kaynak Dosyaları

`lib/core/l10n/en.i18n.json` ve `tr.i18n.json` — İngilizce temel dil, Türkçe çeviri.

### Çeviri Kullanımı

```dart
// String erişimi
Text(context.t.auth.loginButton)

// Parametreli string
Text(context.t.dashboard.welcome(name: user.name))
```

> `context.t` — `lib/core/l10n/strings.g.dart` tarafından sağlanan extension'dır.

### Yeni Anahtar Ekleme

1. Her iki JSON dosyasına aynı yapıyı ekle
2. `dart run build_runner build --delete-conflicting-outputs` çalıştır
3. Tip güvenli accessor otomatik oluşur

### Dil Değiştirme

`SettingsCubit.setLocale(locale)` → `app.dart` içindeki `BlocConsumer` → `LocaleSettings.setLocale(...)` → `SharedPreferences`'a kaydedilir.

---

## 11. Tema

### Kullanım

```dart
// AppThemeExtension'dan spacing/radius/renk
final ext = Theme.of(context).extension<AppThemeExtension>()!;
SizedBox(height: ext.spacingMd)               // 16
Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(ext.radiusMd)))

// Context extension (lib/core/utils/extensions.dart)
context.colorScheme.primary
context.textTheme.titleLarge
context.isDarkMode
```

### Tema Ekleme / Değiştirme

- Renk şeması: `lib/core/theme/app_theme.dart` → `FlexScheme.xxx` değiştir
- Özel token'lar: `lib/core/theme/app_theme_extension.dart` → `AppThemeExtension`'a alan ekle, `copyWith` ve `lerp` güncelle

---

## 12. Çevre Değişkenleri

### Dosya Yapısı

```
.env.dev    # Development ortamı (git'e commit edilmez)
.env.prod   # Production ortamı (git'e commit edilmez)
```

`.env` dosya içeriği örneği:

```
API_BASE_URL=https://api.dev.example.com
SENTRY_DSN=https://xxx@sentry.io/yyy
```

### Nasıl Çalışır

1. `envied_generator`, `.env` dosyalarını okuyarak `lib/core/env/env.g.dart` üretir (obfuscate edilmiş)
2. `AppConfig.apiBaseUrl` → `kReleaseMode ? ProdEnv.apiBaseUrl : DevEnv.apiBaseUrl`
3. Kod üretmek için: `dart run build_runner build --delete-conflicting-outputs`

> `.env` dosyaları asla versiyon kontrolüne eklenmez. `.gitignore`'a ekli olduğundan emin ol.

---

## 13. Test Yazma Kuralları

### Klasör Yapısı

```
test/
└── unit/
    └── <feature>/
        └── <feature>_bloc_test.dart
        └── <feature>_cubit_test.dart
```

### Mock Tanımlama (mocktail)

```dart
class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
```

### Fallback Değer Kaydı

Değer tipi (value type) parametreler için `setUpAll` içinde `registerFallbackValue` kullanılmalıdır:

```dart
setUpAll(() {
  registerFallbackValue(const LoginParams(email: 'a@b.com', password: '1234'));
});
```

### Test Yapısı

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

### Cubit Testleri

```dart
test('başlangıç state ThemeMode.system içermelidir', () {
  when(() => mockPrefs.getString(any())).thenReturn(null);
  when(() => mockPrefs.getBool(any())).thenReturn(null);

  final cubit = SettingsCubit(mockPrefs);

  expect(cubit.state.themeMode, ThemeMode.system);
});
```

### Neyi Test Et

- ✅ BLoC ve Cubit — tüm event/durum geçişleri
- ✅ Use case'ler — repository mock'lanarak
- ✅ Repository impl — datasource mock'lanarak
- ❌ `*.g.dart`, `*.freezed.dart`, `injection.config.dart` — generated dosyaları test etme
- ❌ Widget testleri — hariç tutulmuştur, `test/widget_test.dart` sadece placeholder

---

## 14. Kod Stili ve Linting

### Temel Kural

`analysis_options.yaml` — `package:flutter_lints/flutter.yaml` üzerine genişler.

### Strict Analyzer Ayarları

```yaml
analyzer:
  language:
    strict-casts: true       # Implicit cast'e izin yok
    strict-inference: true   # Tip çıkarımı zorunlu
    strict-raw-types: true   # Raw generic kullanılamaz
```

### Aktif Linter Kuralları (seçilmiş önemliler)

| Kural | Açıklama |
|---|---|
| `always_declare_return_types` | Return tipi her zaman yazılmalı |
| `prefer_single_quotes` | String'lerde `'` kullanılmalı |
| `prefer_const_constructors` | Mümkünse `const` constructor kullanılmalı |
| `prefer_final_fields` | Değişmeyen field'lar `final` olmalı |
| `prefer_final_locals` | Değişmeyen yerel değişkenler `final` olmalı |
| `avoid_print` | `print()` yerine logging kullanılmalı |
| `use_key_in_widget_constructors` | Widget'larda `key` parametresi zorunlu |
| `directives_ordering` | Import sıralaması: dart → flutter → paketler → proje |

### Analyzer Dışlanan Dosyalar

```yaml
exclude:
  - '**/*.g.dart'
  - '**/*.freezed.dart'
  - 'lib/core/di/injection.config.dart'
  - 'lib/core/l10n/strings.g.dart'
```

---

## 15. Sık Kullanılan Komutlar

```bash
# Bağımlılıkları yükle
flutter pub get

# Code generation (Freezed, injectable, slang, envied)
dart run build_runner build --delete-conflicting-outputs

# Code generation (watch mode — geliştirme sırasında)
dart run build_runner watch --delete-conflicting-outputs

# Testleri çalıştır
flutter test

# Tek test dosyası çalıştır
flutter test test/unit/auth/auth_bloc_test.dart

# Coverage raporu
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Development ortamında çalıştır
flutter run

# Analiz
flutter analyze

# Linting sorunu varsa düzelt
dart fix --apply
```

---

## 16. İsimlendirme Konvansiyonları Özeti

| Artifact | Konvansiyon | Örnek |
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
| Event (concrete) | fiil cümlesi | `LoginRequested`, `AppStarted` |
| State (abstract) | `XState` | `AuthState` |
| State (concrete) | `X + durum` | `AuthLoading`, `AuthAuthenticated` |
| Cubit | `XCubit` | `SettingsCubit` |
| Cubit State | `XState` | `SettingsState` |
| Page | `XPage` | `LoginPage`, `DashboardPage` |
| Private view | `_XView` | `_LoginView` |
| Widget | açıklayıcı isim | `LoginForm`, `ProductCard` |
| DI Module | `XModule` | `CoreModule` |
| Router | `AppRouter`, `AppRoutes` | — |
| Extensions | `XExtension` veya `ContextX` | `AppThemeExtension`, `ContextX` |
| Constants | `AppConstants` | — |
| Config | `AppConfig` | — |
| Env | `DevEnv`, `ProdEnv` | — |
