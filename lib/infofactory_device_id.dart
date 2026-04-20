import 'src/device_id_service.dart';

final _deviceIdService = DeviceIdService();

/// Restituisce un UUID persistente per il dispositivo.
///
/// L'UUID viene letto da storage locale se presente, altrimenti viene creato,
/// salvato e tenuto in memoria per le chiamate successive.
Future<String> getDeviceId() => _deviceIdService.getDeviceId();
