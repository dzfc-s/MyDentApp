# Recommender sistem — MyDent

Hibridni pristup preporuci stomatoloških usluga pacijentu, sastavljen od tri kombinovane strategije. Implementacija: `MyDent.Services/RecommenderService.cs`, izložena preko `GET /Recommendations` (`MyDent.WebAPI/Controllers/RecommendationsController.cs`).

## Pristup

Sistem uvijek prvo pokuša **content-based** i **time-based** preporuke na osnovu istorije pacijenta. Ako pacijent nema nikakvu istoriju (nov pacijent), ili ako te dvije strategije ne vrate ništa (pacijent je već imao sve usluge iz svojih kategorija i nije mu due-a nijedna kontrola), sistem se oslanja na **popularity fallback**.

### 1. Content-based

Na osnovu kategorija usluga koje je pacijent već posjetio (izvedeno iz njegovih `Completed` termina), predlažu se druge aktivne usluge iz tih istih kategorija koje pacijent još nije imao.

Primjer: pacijent je imao "Vađenje zuba" (kategorija "Oralna hirurgija") → predlaže mu se npr. "Ugradnja implanta" (ista kategorija), ako je postoji i pacijent je još nije imao.

### 2. Time-based

Za svaku kategoriju koju je pacijent posjetio, a koja ima postavljen `RecommendedRecallMonths` (npr. redovna kontrola ~6 mjeseci, ortodontska kontrola ~2 mjeseca), provjerava se da li je od zadnje posjete u toj kategoriji prošlo više vremena nego preporučeni period. Ako jeste, ta usluga se predlaže ponovo, sa objašnjenjem da je "vrijeme za kontrolu".

Ovaj isti mehanizam (usporedba zadnje posjete sa `RecommendedRecallMonths`) se koristi i u `MyDent.NotificationWorker/ReminderSchedulerService.cs` za automatsko slanje notifikacija — `RecommenderService` ga koristi kao *upit* (šta bih preporučio sad kad me neko pita), dok `ReminderSchedulerService` ga koristi kao *proaktivnu akciju* (pošalji notifikaciju bez da iko pita).

### 3. Popularity fallback

Kada pacijent nema nijedan `Completed` termin (nov pacijent, nema na osnovu čega raditi content-based/time-based), ili kada mu prve dvije strategije ne vrate nijednu preporuku, predlažu se najčešće rezervisane aktivne usluge u cijeloj klinici (broj termina po usluzi, isključujući otkazane, opadajuće sortirano).

## Odgovor API-ja

Svaka preporuka nosi `Reason` (`Popularity` | `ContentBased` | `TimeBased`) i čitljiv `ReasonDetail` tekst — UI može prikazati zašto je nešto preporučeno ("Na osnovu vaše prethodne posjete za...", "Vrijeme je za kontrolu...", "Popularna usluga u klinici"), ne samo golu listu usluga.

## Autorizacija

`GET /Recommendations` zahtijeva prijavu. Pacijent uvijek dobija svoje preporuke (parametar `patientId` se ignoriše ako ga pošalje neko ko nije Admin). Admin može proslijediti `patientId` da vidi preporuke za bilo kojeg pacijenta (npr. osoblje za šalterom pomaže pacijentu na licu mjesta).
