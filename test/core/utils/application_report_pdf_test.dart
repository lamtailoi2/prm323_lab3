import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/application_report_pdf.dart';
import 'package:internly/models/internship_application.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../helpers/fakes.dart';

void main() {
  // rootBundle needs the test binding to read the bundled font assets.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reportFileName puts the local date in the file name', () {
    expect(
      reportFileName(DateTime(2026, 11, 12, 23, 30)),
      'application-report-2026-11-12.pdf',
    );
    expect(
      reportFileName(DateTime(2026, 1, 5)),
      'application-report-2026-01-05.pdf',
    );
  });

  test('builds a real PDF from the applications', () async {
    final bytes = await buildApplicationReportPdf(
      applications: [
        testApplication('1', appliedAt: DateTime(2026, 9, 18)),
        testApplication(
          '2',
          appliedAt: DateTime(2026, 10, 1),
          status: ApplicationStatus.interview,
          nextStepAt: DateTime(2026, 10, 24),
        ),
      ],
      studentName: 'Test Student',
      generatedAt: DateTime(2026, 11, 12),
    );

    // A PDF always starts with the %PDF- signature.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });

  test('one application still builds a report', () async {
    final bytes = await buildApplicationReportPdf(
      applications: [testApplication('1')],
      studentName: 'Test Student',
      generatedAt: DateTime(2026, 11, 12),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('an empty list is a programming error, never an empty report', () async {
    expect(
      () => buildApplicationReportPdf(
        applications: const [],
        studentName: 'Test Student',
        generatedAt: DateTime(2026, 11, 12),
      ),
      throwsArgumentError,
    );
  });

  test('the bundled Inter faces render Vietnamese names', () async {
    // The service loads these two exact asset paths; a rename would break the
    // report only at runtime, so the path is asserted here.
    final regular = await rootBundle.load(
      'assets/fonts/inter/Inter-Regular.ttf',
    );
    final semibold = await rootBundle.load(
      'assets/fonts/inter/Inter-SemiBold.ttf',
    );

    final bytes = await buildApplicationReportPdf(
      applications: [
        testApplication(
          '1',
          title: 'Thực tập sinh Lập trình',
          companyName: 'Công ty Đại Việt',
        ),
      ],
      studentName: 'Mai Duy Lập',
      generatedAt: DateTime(2026, 11, 12),
      baseFont: pw.Font.ttf(regular),
      boldFont: pw.Font.ttf(semibold),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });
}
