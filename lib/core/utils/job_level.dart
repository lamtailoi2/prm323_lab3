import 'text_fold.dart';

/// Early-career level inferred from a listing's title.
///
/// Google Jobs has no experience-level field and the sync keyword only says
/// which query found the listing, not what the job is (an "internship" query
/// also returns senior roles). The level is therefore read from the title
/// only; listings that do not state an early-career level return `null` and
/// show no badge.
enum JobLevel {
  intern('Intern'),
  fresher('Fresher'),
  junior('Junior');

  const JobLevel(this.label);

  final String label;
}

/// Reads the level from [title], or `null` when it states none.
///
/// `fresher` / `junior` win over `intern` because a title such as
/// "Junior Developer (Internship)" describes the job level, not the contract.
/// A title that states a more senior level is not an early-career job.
JobLevel? jobLevelFor({required String title}) {
  final text = foldText(title);
  if (_hasAny(text, _seniority)) return null;

  if (containsWords(text, 'fresher') ||
      containsWords(text, 'fresh graduate') ||
      containsWords(text, 'moi tot nghiep') ||
      containsWords(text, 'new grad')) {
    return JobLevel.fresher;
  }
  if (containsWords(text, 'junior') || containsWords(text, 'jr')) {
    return JobLevel.junior;
  }
  if (containsWords(text, 'intern') ||
      containsWords(text, 'internship') ||
      containsWords(text, 'thuc tap') ||
      containsWords(text, 'tts')) {
    return JobLevel.intern;
  }
  return null;
}

/// Words that describe a level above the early-career pool.
const List<String> _seniority = <String>[
  'senior',
  'sr',
  'lead',
  'principal',
  'staff',
  'manager',
  'head',
  'director',
  'architect',
];

bool _hasAny(String text, List<String> terms) {
  return terms.any((term) => containsWords(text, term));
}
