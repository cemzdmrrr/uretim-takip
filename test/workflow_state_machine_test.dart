import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/services/workflow_state_machine.dart';

void main() {
  group('WorkflowStateMachine normalizasyonu', () {
    test('Türkçe karakter ve boşlukları durum anahtarına dönüştürür', () {
      expect(
        WorkflowStateMachine.normalize('  Kısmi Tamamlandı  '),
        'kismi_tamamlandi',
      );
      expect(
        WorkflowStateMachine.normalize('Sevk Ediliyor'),
        'sevk_ediliyor',
      );
    });

    test('tamamlanan ve reddedilen eş anlamlı durumları tanır', () {
      expect(WorkflowStateMachine.isCompleted('sevk_edildi'), isTrue);
      expect(WorkflowStateMachine.isCompleted('tamamlandı'), isTrue);
      expect(WorkflowStateMachine.isRejected('kalite_red'), isTrue);
      expect(WorkflowStateMachine.isRejected('kalite_reddedildi'), isTrue);
    });
  });

  group('WorkflowStateMachine üretim geçişleri', () {
    test('bekleyenden onaya ve işleme geçişe izin verir', () {
      expect(
        WorkflowStateMachine.canTransition(
          fromStatus: 'bekleyen',
          toStatus: 'onaylandi',
        ),
        isTrue,
      );
      expect(
        WorkflowStateMachine.canTransition(
          fromStatus: 'atandi',
          toStatus: 'uretimde',
        ),
        isTrue,
      );
    });

    test('kısmi tamamlanan işi işlemde tutar ve tamamlamaya izin verir', () {
      expect(
        WorkflowStateMachine.canTransition(
          fromStatus: 'uretimde',
          toStatus: 'kismi_tamamlandi',
        ),
        isTrue,
      );
      expect(
        WorkflowStateMachine.canTransition(
          fromStatus: 'kismi_tamamlandi',
          toStatus: 'uretimde',
        ),
        isTrue,
      );
      expect(
        WorkflowStateMachine.canTransition(
          fromStatus: 'kismi_tamamlandi',
          toStatus: 'tamamlandi',
        ),
        isTrue,
      );
    });

    test('iptal edilen iş yeniden başlatılamaz', () {
      expect(
        WorkflowStateMachine.canTransition(
          fromStatus: 'iptal',
          toStatus: 'uretimde',
        ),
        isFalse,
      );
      expect(
        () => WorkflowStateMachine.ensureTransition(
          fromStatus: 'iptal',
          toStatus: 'uretimde',
          context: 'test',
        ),
        throwsException,
      );
    });
  });
}
