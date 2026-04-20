# infofactory_device_id

`infofactory_device_id` e una libreria Flutter che espone un solo metodo pubblico:

- `getDeviceId()`

Il metodo restituisce un identificativo UUID (v4) del device/app-installation con queste regole:

1. Se l'UUID e gia in memoria, lo restituisce subito (massime performance).
2. Se non e in memoria, prova a leggerlo da secure storage.
3. Se non esiste (o e vuoto), genera un nuovo UUID, lo salva su secure storage e lo ritorna.

In questo modo l'ID resta stabile tra avvii successivi finche i dati persistiti sono disponibili.

## Caratteristiche

- API minima: un solo metodo pubblico.
- UUID v4 generato automaticamente.
- Cache in memoria per evitare I/O ripetuto.
- Persistenza su `flutter_secure_storage`.
- Gestione sicura di chiamate concorrenti durante la prima inizializzazione.

## Installazione

Aggiungi la dipendenza nel tuo `pubspec.yaml`:

```yaml
dependencies:
  infofactory_device_id:
    git:
      url: https://github.com/infofactory/flutter_infofactory_device_id.git
      ref: main
```

Poi esegui:

```bash
flutter pub get
```

## Utilizzo

Importa la libreria e chiama `getDeviceId()`:

```dart
import 'package:infofactory_device_id/infofactory_device_id.dart';

Future<void> loadDeviceId() async {
  final deviceId = await getDeviceId();
  // Usa deviceId per analytics, logging, correlazione eventi, ecc.
}
```

## API pubblica

```dart
Future<String> getDeviceId()
```

Restituisce sempre una stringa UUID valida.

## Dettagli di persistenza

La libreria usa secure storage con chiave:

- `infofactory_device_id`

Comportamento atteso:

- **Android**: in caso di "Clear data" dell'app, il valore viene cancellato.
- **iOS**: il Keychain puo sopravvivere alla reinstallazione in diversi casi, ma non e una garanzia assoluta in ogni scenario.

Se il requisito e "non perdere mai l'ID", e consigliata una strategia server-side (sincronizzazione con backend/account).
