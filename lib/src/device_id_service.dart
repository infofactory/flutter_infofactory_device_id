import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

const String deviceIdStorageKey = 'infofactory_device_id';

typedef ReadDeviceId = Future<String?> Function();
typedef WriteDeviceId = Future<void> Function(String value);
typedef GenerateUuid = String Function();

class DeviceIdService {
  DeviceIdService({
    ReadDeviceId? readDeviceId,
    WriteDeviceId? writeDeviceId,
    GenerateUuid? generateUuid,
  }) : _readDeviceId = readDeviceId ?? _defaultReadDeviceId,
       _writeDeviceId = writeDeviceId ?? _defaultWriteDeviceId,
       _generateUuid = generateUuid ?? _defaultGenerateUuid;

  final ReadDeviceId _readDeviceId;
  final WriteDeviceId _writeDeviceId;
  final GenerateUuid _generateUuid;

  String? _cachedDeviceId;
  Future<String>? _inFlightGetDeviceId;

  Future<String> getDeviceId() async {
    final cachedDeviceId = _cachedDeviceId;
    if (_isValidDeviceId(cachedDeviceId)) {
      return cachedDeviceId!;
    }

    final inFlightGetDeviceId = _inFlightGetDeviceId;
    if (inFlightGetDeviceId != null) {
      return inFlightGetDeviceId;
    }

    final loadOrCreateFuture = _loadOrCreateDeviceId();
    _inFlightGetDeviceId = loadOrCreateFuture;

    try {
      return await loadOrCreateFuture;
    } finally {
      if (identical(_inFlightGetDeviceId, loadOrCreateFuture)) {
        _inFlightGetDeviceId = null;
      }
    }
  }

  Future<String> _loadOrCreateDeviceId() async {
    final storedDeviceId = await _readDeviceId();
    if (_isValidDeviceId(storedDeviceId)) {
      _cachedDeviceId = storedDeviceId;
      return storedDeviceId!;
    }

    final generatedDeviceId = _generateUuid();
    await _writeDeviceId(generatedDeviceId);
    _cachedDeviceId = generatedDeviceId;
    return generatedDeviceId;
  }
}

bool _isValidDeviceId(String? value) => value != null && value.isNotEmpty;

const _defaultSecureStorage = FlutterSecureStorage();

Future<String?> _defaultReadDeviceId() async {
  return _defaultSecureStorage.read(key: deviceIdStorageKey);
}

Future<void> _defaultWriteDeviceId(String value) async {
  await _defaultSecureStorage.write(key: deviceIdStorageKey, value: value);
}

String _defaultGenerateUuid() => const Uuid().v4();
