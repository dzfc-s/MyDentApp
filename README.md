# MyDentApp

Sistem za upravljanje stomatološkom ordinacijom: REST API (ASP.NET Core), odvojeni pozadinski servis za notifikacije (RabbitMQ worker), desktop administratorska aplikacija i mobilna aplikacija za pacijente (Flutter).

## Arhitektura

- **MyDent.WebAPI** — glavni REST API (autentifikacija/autorizacija, CRUD nad svim entitetima, rezervacije, plaćanja, preporuke).
- **MyDent.NotificationWorker** — odvojeni mikroservis (poseban kontejner) koji sluša RabbitMQ i upisuje/šalje notifikacije, te periodično šalje podsjetnike za kontrole.
- **MyDent.Services / MyDent.Model / MyDent.Common.Services** — poslovna logika, EF Core modeli i baza, zajednički servisi (npr. kriptografija lozinki).
- **UI/mydent_desktop** — Flutter desktop aplikacija (administracija ordinacije).
- **UI/mydent_mobile** — Flutter mobilna aplikacija (pacijenti).
- **SQL Server** i **RabbitMQ** pokreću se kroz Docker.

Opis recommender sistema (hibridni content-based / time-based / popularity pristup): [recommender-dokumentacija.md](./recommender-dokumentacija.md)

## Preduslovi

- Docker i Docker Compose
- .NET 9 SDK (samo ako se API/Worker pokreću lokalno, van Dockera)
- Flutter SDK (najnovija stabilna verzija)
- Android Studio / AVD emulator (za mobilnu aplikaciju) ili fizički Android uređaj

## Pokretanje aplikacije

### 1. Konfiguracija

Kopirati `.env.example` u `.env` i popuniti stvarnim vrijednostima:

```
cp .env.example .env
```

Za lokalno pokretanje (bez integracije stvarnog plaćanja) default vrijednosti za bazu i RabbitMQ iz `.env.example` su dovoljne; `Stripe__SecretKey` treba zamijeniti stvarnim test ključem ako se testira modul plaćanja.

### 2. Pokretanje backend infrastrukture (SQL Server, RabbitMQ, API, Worker)

Iz root foldera repozitorija:

```
docker compose up --build
```

Ovo pokreće:

- SQL Server (port iz `.env`, `DB_PORT`, default 1435)
- RabbitMQ (AMQP port 5672, management UI na 15672)
- API na `http://localhost:5126`
- Notification Worker (bez izloženog porta; sluša RabbitMQ u pozadini)

Baza podataka i seed podaci (korisnici, usluge, doktori, termini itd.) kreiraju se automatski putem EF Core migracija pri prvom pokretanju API-ja.

Napomena: ako se API i Worker pokreću lokalno sa `dotnet run` (van Dockera), u Dockeru je dovoljno ostaviti samo bazu i RabbitMQ:

```
docker compose up mydent-sqlserver-210057 mydent-rabbitmq-210057
```

U tom slučaju `.env` treba koristiti `localhost` kao host za bazu i RabbitMQ (već je tako podešeno u `.env.example`).

### 3. Pokretanje desktop aplikacije (administracija)

```
cd UI/mydent_desktop
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5126
```

Build za distribuciju:

```
flutter build windows --release --dart-define=API_BASE_URL=http://localhost:5126
```

EXE fajl nakon builda: `UI/mydent_desktop/build/windows/x64/runner/Release/`

### 4. Pokretanje mobilne aplikacije (pacijenti)

Za Android emulator (AVD), API adresa mora biti `10.0.2.2` (standardna adresa hosta iz emulatora):

```
cd UI/mydent_mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5126
```

Build APK-a:

```
flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:5126
```

APK fajl nakon builda: `UI/mydent_mobile/build/app/outputs/flutter-apk/app-release.apk`

## Testni korisnici

| Kontekst | Korisničko ime | Lozinka |
|---|---|---|
| Desktop verzija (uloga Admin) | desktop | test |
| Mobilna verzija (uloga Patient) | mobile | test |

