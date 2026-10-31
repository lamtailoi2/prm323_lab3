import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/job_role.dart';

void main() {
  test('classifies IT roles from real listing titles', () {
    expect(jobRoleFor(title: 'Frontend Developer Intern'), JobRole.frontend);
    expect(
      jobRoleFor(title: 'Software Engineer (Backend Intern)'),
      JobRole.backend,
    );
    expect(
      jobRoleFor(title: 'Fullstack Developer Intern (ReactJS · NodeJS)'),
      JobRole.fullStack,
    );
    expect(
      jobRoleFor(title: 'Mobile Developers (React Native, Flutter)'),
      JobRole.mobile,
    );
    expect(
      jobRoleFor(title: 'Thực Tập Sinh Phân Tích Dữ Liệu'),
      JobRole.dataAi,
    );
    expect(
      jobRoleFor(title: 'Thực Tập Sinh Kiểm Thử Phần Mềm'),
      JobRole.tester,
    );
    expect(jobRoleFor(title: 'DevOps Intern'), JobRole.devOps);
    expect(jobRoleFor(title: 'IT Specialist Intern'), JobRole.otherIt);
  });

  test('rejects non-IT listings before matching data or mobile words', () {
    expect(
      jobRoleFor(title: 'HR Intern – Employee Records & Data Governance'),
      isNull,
    );
    expect(jobRoleFor(title: 'CSKH LỚP STEM/ROBOT'), isNull);
    expect(jobRoleFor(title: 'Sales Intern'), isNull);
    expect(jobRoleFor(title: 'Cho thuê chuyên gia Lập Trình Mobile'), isNull);
  });

  test('uses the sync keyword when the title is generic', () {
    expect(
      jobRoleFor(
        title: 'INTERNSHIP IT Program',
        searchKeyword: 'thực tập backend',
      ),
      JobRole.backend,
    );
  });

  test('uses strong skill tags only as a fallback', () {
    expect(
      jobRoleFor(title: 'Internship', skills: const ['Flutter']),
      JobRole.mobile,
    );
    expect(
      jobRoleFor(title: 'Internship', skills: const ['React']),
      JobRole.frontend,
    );
  });

  test('non-IT titles from the real pool stay out of every role', () {
    expect(
      jobRoleFor(
        title: 'Sale MKT Intern (Tiếng Nhật N3)',
        searchKeyword: 'thực tập frontend',
      ),
      isNull,
    );
    expect(
      jobRoleFor(
        title: 'Executive Assistant Intern',
        searchKeyword: 'IT internship Vietnam',
        skills: const ['React'],
      ),
      isNull,
    );
    expect(
      jobRoleFor(
        title: 'Project Assistant Intern - Non-Tech (Fluent In English)',
      ),
      isNull,
    );
  });
}
