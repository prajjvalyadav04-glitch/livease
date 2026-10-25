import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livease/core/widgets.dart';
import 'package:livease/features/complaints/complaint.dart';

void main() {
  testWidgets('EmptyState shows title and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(title: 'No notices yet', subtitle: 'Check back soon'),
        ),
      ),
    );

    expect(find.text('No notices yet'), findsOneWidget);
    expect(find.text('Check back soon'), findsOneWidget);
  });

  testWidgets('StatusChip renders its label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusChip(label: 'Open', color: Colors.orange),
        ),
      ),
    );

    expect(find.text('Open'), findsOneWidget);
  });

  test('ComplaintStatus maps to and from Firestore keys', () {
    expect(ComplaintStatus.fromKey('in_progress'), ComplaintStatus.inProgress);
    expect(ComplaintStatus.fromKey('resolved'), ComplaintStatus.resolved);
    // Unknown / missing values fall back to open.
    expect(ComplaintStatus.fromKey('nonsense'), ComplaintStatus.open);
    expect(ComplaintStatus.fromKey(null), ComplaintStatus.open);
  });
}
