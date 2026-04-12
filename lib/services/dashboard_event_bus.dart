// Global event bus for dashboard updates
import 'dart:async';

class DashboardEventBus {
  static final DashboardEventBus _instance = DashboardEventBus._internal();
  factory DashboardEventBus() => _instance;
  DashboardEventBus._internal();

  final StreamController<Map<String, dynamic>> _controller = 
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  Stream<Map<String, dynamic>> get onAtamaUpdate => _controller.stream;

  void broadcastAtamaUpdate(Map<String, dynamic> atamaData) {
    _controller.add({
      'event_type': 'atama_update',
      'data': atamaData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void broadcastModelStatusUpdate(String modelId, String stage, String status) {
    _controller.add({
      'event_type': 'model_status_update',
      'data': {
        'model_id': modelId,
        'stage': stage,
        'status': status,
      },
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void dispose() {
    _controller.close();
  }
}