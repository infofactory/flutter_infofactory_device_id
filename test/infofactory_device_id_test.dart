import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:infofactory_device_id/infofactory_device_id.dart';
import 'package:infofactory_device_id/src/device_id_service.dart';

void main() {
  group('DeviceIdService', () {
    test('legge da storage al primo accesso e usa cache in memoria', () async {
      final storage = _FakeDeviceIdStorage(storedValue: _uuid1);
      var generateCalls = 0;
      final service = DeviceIdService(
        readDeviceId: storage.read,
        writeDeviceId: storage.write,
        generateUuid: () {
          generateCalls++;
          return _uuid2;
        },
      );

      final first = await service.getDeviceId();
      final second = await service.getDeviceId();

      expect(first, _uuid1);
      expect(second, _uuid1);
      expect(storage.readCalls, 1);
      expect(storage.writeCalls, 0);
      expect(generateCalls, 0);
    });

    test('genera e persiste UUID quando storage non ha un valore', () async {
      final storage = _FakeDeviceIdStorage();
      var generateCalls = 0;
      final service = DeviceIdService(
        readDeviceId: storage.read,
        writeDeviceId: storage.write,
        generateUuid: () {
          generateCalls++;
          return _uuid1;
        },
      );

      final first = await service.getDeviceId();
      final second = await service.getDeviceId();

      expect(first, _uuid1);
      expect(second, _uuid1);
      expect(storage.storedValue, _uuid1);
      expect(storage.readCalls, 1);
      expect(storage.writeCalls, 1);
      expect(generateCalls, 1);
    });

    test('rigenera UUID quando storage contiene stringa vuota', () async {
      final storage = _FakeDeviceIdStorage(storedValue: '');
      var generateCalls = 0;
      final service = DeviceIdService(
        readDeviceId: storage.read,
        writeDeviceId: storage.write,
        generateUuid: () {
          generateCalls++;
          return _uuid2;
        },
      );

      final value = await service.getDeviceId();

      expect(value, _uuid2);
      expect(storage.storedValue, _uuid2);
      expect(storage.readCalls, 1);
      expect(storage.writeCalls, 1);
      expect(generateCalls, 1);
    });

    test(
      'coalesce chiamate concorrenti in una singola inizializzazione',
      () async {
        final storage = _FakeDeviceIdStorage(
          readDelay: const Duration(milliseconds: 25),
        );
        var generateCalls = 0;
        final service = DeviceIdService(
          readDeviceId: storage.read,
          writeDeviceId: storage.write,
          generateUuid: () {
            generateCalls++;
            return _uuid1;
          },
        );

        final results = await Future.wait(
          List.generate(5, (_) => service.getDeviceId()),
        );

        expect(results.toSet(), {_uuid1});
        expect(storage.readCalls, 1);
        expect(storage.writeCalls, 1);
        expect(generateCalls, 1);
      },
    );

    test('propaga errore di lettura e consente retry successivo', () async {
      final storage = _FakeDeviceIdStorage(throwOnRead: true);
      final service = DeviceIdService(
        readDeviceId: storage.read,
        writeDeviceId: storage.write,
        generateUuid: () => _uuid1,
      );

      await expectLater(
        service.getDeviceId(),
        throwsA(isA<_FakeStorageException>()),
      );

      storage.throwOnRead = false;
      storage.storedValue = _uuid2;

      final retried = await service.getDeviceId();

      expect(retried, _uuid2);
      expect(storage.readCalls, 2);
      expect(storage.writeCalls, 0);
    });

    test('propaga errore di scrittura e rigenera al retry', () async {
      final storage = _FakeDeviceIdStorage(throwOnWrite: true);
      var seed = 0;
      final service = DeviceIdService(
        readDeviceId: storage.read,
        writeDeviceId: storage.write,
        generateUuid: () {
          seed++;
          return '00000000-0000-4000-8000-00000000000$seed';
        },
      );

      await expectLater(
        service.getDeviceId(),
        throwsA(isA<_FakeStorageException>()),
      );

      storage.throwOnWrite = false;
      final retried = await service.getDeviceId();

      expect(retried, '00000000-0000-4000-8000-000000000002');
      expect(storage.storedValue, '00000000-0000-4000-8000-000000000002');
      expect(storage.readCalls, 2);
      expect(storage.writeCalls, 2);
    });
  });

  test('API pubblica getDeviceId salva e riusa UUID in local storage', () async {
    FlutterSecureStorage.setMockInitialValues({});

    final first = await getDeviceId();
    final second = await getDeviceId();
    const secureStorage = FlutterSecureStorage();

    final uuidPattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );

    expect(uuidPattern.hasMatch(first), isTrue);
    expect(second, first);
    expect(await secureStorage.read(key: deviceIdStorageKey), first);
  });
}

const _uuid1 = '7ec9f6e5-14c2-4d14-b2e2-704e4e9b93e0';
const _uuid2 = '189cc1f0-70d0-40d3-89d5-3f3fe62445a6';

class _FakeDeviceIdStorage {
  _FakeDeviceIdStorage({
    this.storedValue,
    this.throwOnRead = false,
    this.throwOnWrite = false,
    this.readDelay = Duration.zero,
  });

  String? storedValue;
  bool throwOnRead;
  bool throwOnWrite;
  Duration readDelay;
  int readCalls = 0;
  int writeCalls = 0;

  Future<String?> read() async {
    readCalls++;
    if (readDelay > Duration.zero) {
      await Future.delayed(readDelay);
    }
    if (throwOnRead) {
      throw const _FakeStorageException('read');
    }
    return storedValue;
  }

  Future<void> write(String value) async {
    writeCalls++;
    if (throwOnWrite) {
      throw const _FakeStorageException('write');
    }
    storedValue = value;
  }
}

class _FakeStorageException implements Exception {
  const _FakeStorageException(this.operation);

  final String operation;
}
