import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/job_level.dart';

void main() {
  test('reads the level from the title', () {
    expect(jobLevelFor(title: 'Flutter Developer Intern'), JobLevel.intern);
    expect(jobLevelFor(title: 'Fresher Backend Developer'), JobLevel.fresher);
    expect(jobLevelFor(title: 'Junior Data Analyst'), JobLevel.junior);
    expect(jobLevelFor(title: 'Thực Tập Sinh Kiểm Thử'), JobLevel.intern);
    expect(jobLevelFor(title: 'TTS Backend'), JobLevel.intern);
    expect(
      jobLevelFor(title: 'Mới Tốt Nghiệp - Data Analyst'),
      JobLevel.fresher,
    );
    expect(jobLevelFor(title: 'New Grad Software Engineer'), JobLevel.fresher);
    expect(jobLevelFor(title: 'Jr. Mobile Developer'), JobLevel.junior);
  });

  test('fresher and junior win over the internship word', () {
    expect(
      jobLevelFor(title: 'Junior Developer (Internship)'),
      JobLevel.junior,
    );
    expect(jobLevelFor(title: 'Fresher Intern'), JobLevel.fresher);
  });

  test('does not label a more senior title as early career', () {
    expect(jobLevelFor(title: 'Senior Backend Engineer'), isNull);
    expect(jobLevelFor(title: 'Lead Flutter Developer'), isNull);
    expect(jobLevelFor(title: 'Principal Engineer (Internship)'), isNull);
  });

  test('does not read "international" as an internship', () {
    expect(jobLevelFor(title: 'International Sales Executive'), isNull);
  });

  test('returns null when the listing states no level', () {
    expect(jobLevelFor(title: 'Backend Developer'), isNull);
    expect(jobLevelFor(title: 'Management Trainee'), isNull);
  });
}
