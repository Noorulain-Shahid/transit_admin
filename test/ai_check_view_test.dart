import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transit_admin/widgets/ai_check_view.dart';
import 'package:transit_core/transit_core.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('a slip check with issues opens on its warnings', (t) async {
    await t.pumpWidget(
      _host(
        SlipCheckView(
          check: SlipCheck(
            provider: 'jazzcash',
            amountPaisa: 450000,
            expectedAmountPaisa: 500000,
            transactionId: '446804416088',
            receiverName: 'Talha Aslam',
            receiverAccountLast4: '3717',
            issues: const [SlipCheck.amountMismatch],
            checkedAt: DateTime(2026, 11, 20),
          ),
        ),
      ),
    );
    expect(find.text('⚠️ AI: 1 issue'), findsOneWidget);
    expect(find.textContaining('Rs 5,000'), findsOneWidget);
    expect(find.text('446804416088'), findsOneWidget);
    expect(find.text('Talha Aslam · ••3717'), findsOneWidget);
  });

  testWidgets('a matching slip stays folded until tapped', (t) async {
    await t.pumpWidget(
      _host(
        const SlipCheckView(
          check: SlipCheck(provider: 'easypaisa', amountPaisa: 100000),
        ),
      ),
    );
    expect(find.text('✅ AI: matches'), findsOneWidget);
    expect(find.text('Rs 1,000'), findsNothing);
    await t.tap(find.text('Screenshot matches the bill'));
    await t.pump();
    expect(find.text('Rs 1,000'), findsOneWidget);
  });

  testWidgets('a document check lists fields, name match and issues', (
    t,
  ) async {
    await t.pumpWidget(
      _host(
        DocCheckView(
          check: DocCheck(
            docType: 'drivingLicense',
            fields: const {'name': 'Talha Aslam', 'categories': 'M/CAR'},
            nameMatchPercent: 100,
            expiryDate: DateTime(2025, 3, 11),
            issues: const [DocCheck.expired, DocCheck.noCommercialCategory],
          ),
        ),
      ),
    );
    expect(find.text('⚠️ AI: 2 issues'), findsOneWidget);
    expect(find.text('100% with the profile'), findsOneWidget);
    expect(find.textContaining('expired on 11 Mar 2025'), findsOneWidget);
    expect(find.text('M/CAR'), findsOneWidget);
  });
}
