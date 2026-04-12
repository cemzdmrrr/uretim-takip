import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/services/dashboard_event_bus.dart';

void main() {
  group('DashboardEventBus', () {
    late DashboardEventBus bus;

    setUp(() {
      bus = DashboardEventBus();
    });

    test('is a singleton', () {
      final bus2 = DashboardEventBus();
      expect(identical(bus, bus2), isTrue);
    });

    test('broadcastAtamaUpdate emits event', () async {
      final data = {'model_id': '123', 'stage': 'dokuma'};

      final future = bus.stream.first;
      bus.broadcastAtamaUpdate(data);
      final event = await future;

      expect(event['event_type'], 'atama_update');
      expect(event['data'], data);
      expect(event['timestamp'], isNotNull);
    });

    test('broadcastModelStatusUpdate emits event', () async {
      final future = bus.stream.first;
      bus.broadcastModelStatusUpdate('m1', 'dokuma', 'tamamlandi');
      final event = await future;

      expect(event['event_type'], 'model_status_update');
      expect(event['data']['model_id'], 'm1');
      expect(event['data']['stage'], 'dokuma');
      expect(event['data']['status'], 'tamamlandi');
    });

    test('broadcast stream supports multiple listeners', () async {
      int count = 0;
      final sub1 = bus.stream.listen((_) => count++);
      final sub2 = bus.stream.listen((_) => count++);

      bus.broadcastAtamaUpdate({'test': true});

      // Allow microtask queue to process
      await Future.delayed(Duration.zero);
      expect(count, 2);

      await sub1.cancel();
      await sub2.cancel();
    });
  });
}
