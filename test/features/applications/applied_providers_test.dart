import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/distinct_listings.dart';
import 'package:internly/features/applications/viewmodels/applied_providers.dart';
import 'package:internly/services/application_service.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeApplicationService applications;
  late ProviderContainer container;

  setUp(() {
    applications = FakeApplicationService();
    container = ProviderContainer.test(
      overrides: [applicationServiceProvider.overrideWithValue(applications)],
    );
  });

  tearDown(() => applications.dispose());

  Future<Set<String>> next() => container.read(appliedJobsProvider.future);

  test('maps tracked applications to job identities (CR-14)', () async {
    applications.results = [
      testApplication('1', title: 'Thực tập sinh Java', companyName: 'FPT'),
    ];
    container.listen(appliedJobsProvider, (_, _) {});

    expect(await next(), {jobIdentity('Thuc tap sinh Java', 'fpt')});
  });

  test('follows new snapshots, down to none', () async {
    applications.results = [testApplication('1')];
    final seen = <Set<String>>[];
    container.listen(appliedJobsProvider, (_, next) {
      if (next.asData?.value case final value?) seen.add(value);
    });
    await next();
    // Lets the fake subscribe to its update stream before the next snapshot.
    await Future<void>.delayed(Duration.zero);

    applications.emit(const []);
    await Future<void>.delayed(Duration.zero);
    expect(seen.last, isEmpty);
  });
}
