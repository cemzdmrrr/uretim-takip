import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';

void main() {
  group('LoadingWidget', () {
    testWidgets('shows CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingWidget())),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingWidget(mesaj: 'Yükleniyor...')),
        ),
      );
      expect(find.text('Yükleniyor...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides message when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingWidget())),
      );
      // Only the progress indicator, no text
      expect(find.byType(Text), findsNothing);
    });
  });

  group('EmptyStateWidget', () {
    testWidgets('shows icon and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              mesaj: 'Veri bulunamadı',
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('Veri bulunamadı'), findsOneWidget);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.notifications_off,
              mesaj: 'Bildirim yok',
              altMesaj: 'Yeni bildirimler burada görünecek',
            ),
          ),
        ),
      );
      expect(find.text('Bildirim yok'), findsOneWidget);
      expect(find.text('Yeni bildirimler burada görünecek'), findsOneWidget);
    });

    testWidgets('hides subtitle when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              mesaj: 'Boş',
            ),
          ),
        ),
      );
      expect(find.text('Boş'), findsOneWidget);
      // Only the main message, no subtitle
      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('SnackBarExtension', () {
    testWidgets('showSnackBar displays message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.showSnackBar('Test mesajı'),
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap'));
      await tester.pump();
      expect(find.text('Test mesajı'), findsOneWidget);
    });

    testWidgets('showErrorSnackBar shows red background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.showErrorSnackBar('Hata!'),
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap'));
      await tester.pump();
      expect(find.text('Hata!'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red);
    });

    testWidgets('showSuccessSnackBar shows green background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.showSuccessSnackBar('Başarılı!'),
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap'));
      await tester.pump();
      expect(find.text('Başarılı!'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.green);
    });
  });
}
