import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/l10n/l10n.dart';
import 'package:hangout/theme/app_colors.dart';
import 'package:hangout/theme/app_theme.dart';
import 'package:hangout/widgets/hangout_button.dart';
import 'package:hangout/widgets/hangout_chips.dart';

// The app itself boots Firebase and Supabase in main(), so a full-app smoke
// test isn't meaningful here. These cover the design-system layer instead.

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('primary button renders its label and fires onPressed',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(
      HangoutButton(label: "I'm in", onPressed: () => taps++),
    ));

    expect(find.text("I'm in"), findsOneWidget);

    await tester.tap(find.byType(HangoutButton));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('disabled button does not fire', (tester) async {
    await tester.pumpWidget(_host(
      const HangoutButton(label: 'Round up the crew'),
    ));

    await tester.tap(find.byType(HangoutButton));
    await tester.pumpAndSettle();
    // No callback to assert on; reaching here without an exception is the test.
    expect(find.text('Round up the crew'), findsOneWidget);
  });

  testWidgets('rating badge formats to one decimal', (tester) async {
    await tester.pumpWidget(_host(HangoutBadge.rating(4.75)));
    expect(find.text('4.8'), findsOneWidget);
  });

  testWidgets('filter tabs report the tapped tab', (tester) async {
    String? picked;
    await tester.pumpWidget(_host(
      SizedBox(
        width: 320,
        child: FilterTabs(
          tabs: const ['All', 'Tonight', 'Nearby'],
          value: 'All',
          onChanged: (v) => picked = v,
        ),
      ),
    ));

    await tester.tap(find.text('Nearby'));
    await tester.pumpAndSettle();
    expect(picked, 'Nearby');
  });

  test('theme uses the paprika brand colour', () {
    expect(AppTheme.lightTheme.colorScheme.primary, AppColors.paprika500);
  });
}
