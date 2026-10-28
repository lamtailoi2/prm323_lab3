import 'text_fold.dart';

/// IT job families used by Home's "Browse by Role" filter.
///
/// Google Jobs has no category field, so the role is inferred from the title
/// (then the sync keyword, then strong skill tags). Non-IT listings return
/// `null` so the IT-only app does not show HR, sales or customer-service jobs.
enum JobRole {
  frontend('Frontend'),
  backend('Backend'),
  fullStack('Full-stack'),
  mobile('Mobile'),
  dataAi('Data/AI'),
  tester('Tester/QA'),
  devOps('DevOps/Cloud'),
  otherIt('Other IT');

  const JobRole(this.label);

  final String label;
}

/// Classifies a listing into an IT role, or `null` when it is not IT.
///
/// Titles first because they are the strongest signal; the search keyword is
/// the fallback for generic titles such as "IT Intern". Non-IT titles are
/// rejected before role matching so "HR … Data" cannot become a data role.
JobRole? jobRoleFor({
  required String title,
  String? searchKeyword,
  Iterable<String> skills = const <String>[],
}) {
  final titleText = foldText(title);
  final keywordText = foldText(searchKeyword ?? '');

  if (_hasAny(titleText, _nonIt)) return null;

  final fromTitle = _roleIn(titleText);
  if (fromTitle != null) return fromTitle;

  final fromKeyword = _roleIn(keywordText);
  if (fromKeyword != null) return fromKeyword;

  final skillSet = skills.toSet();
  if (skillSet.contains('Flutter') || skillSet.contains('React Native')) {
    return JobRole.mobile;
  }
  if (skillSet.any(const {'React', 'Angular', 'Vue', 'Next.js'}.contains)) {
    return JobRole.frontend;
  }

  if (_hasAny(titleText, _genericIt) || _hasAny(keywordText, _genericIt)) {
    return JobRole.otherIt;
  }
  return null;
}

const List<String> _nonIt = <String>[
  'hr',
  'human resource',
  'human resources',
  'tuyen dung',
  'sales',
  'kinh doanh',
  'marketing',
  'cskh',
  'customer service',
  'customer care',
  'cham soc khach hang',
  'finance',
  'accounting',
  'ke toan',
  'hanh chinh',
  'cho thue',
];

const List<String> _genericIt = <String>[
  'it',
  'software',
  'developer',
  'engineer',
  'lap trinh',
  'cong nghe thong tin',
  'intern',
  'internship',
  'thuc tap',
  'iot',
  'business analyst',
  'ba',
  'pm',
];

JobRole? _roleIn(String text) {
  if (_hasAny(text, const ['full stack', 'fullstack'])) {
    return JobRole.fullStack;
  }
  if (_hasAny(text, const [
    'mobile',
    'android',
    'ios',
    'flutter',
    'react native',
    'app mobile',
    'di dong',
  ])) {
    return JobRole.mobile;
  }
  if (_hasAny(text, const [
    'front end',
    'frontend',
    'web developer',
    'web engineer',
    'react',
    'vue',
    'angular',
    'next js',
    'giao dien',
    'ui',
    'ux',
  ])) {
    return JobRole.frontend;
  }
  if (_hasAny(text, const [
    'back end',
    'backend',
    'php',
    'java',
    'node js',
    'golang',
    'python',
    'api',
    'server',
    'software engineer',
  ])) {
    return JobRole.backend;
  }
  if (_hasAny(text, const [
    'data',
    'analytics',
    'machine learning',
    'artificial intelligence',
    'phan tich du lieu',
    'business intelligence',
    'ai',
  ])) {
    return JobRole.dataAi;
  }
  if (_hasAny(text, const [
    'tester',
    'testing',
    'qa',
    'qc',
    'kiem thu',
    'test',
  ])) {
    return JobRole.tester;
  }
  if (_hasAny(text, const [
    'devops',
    'cloud',
    'aws',
    'azure',
    'kubernetes',
    'docker',
    'sysadmin',
    'ha tang',
  ])) {
    return JobRole.devOps;
  }
  return null;
}

bool _hasAny(String text, List<String> terms) {
  return terms.any((term) {
    final pattern = RegExp('(?<![a-z0-9])${RegExp.escape(term)}(?![a-z0-9])');
    return pattern.hasMatch(text);
  });
}
