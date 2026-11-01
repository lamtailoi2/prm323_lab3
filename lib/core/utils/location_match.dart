import 'text_fold.dart';

/// Spellings of the Update preferences quick-select cities, folded. Google
/// Jobs writes Vietnamese names ("Thành phố Hồ Chí Minh, Hồ Chí Minh",
/// "Hà Nội", "Đà Nẵng (+1 vị trí khác)") while the sheet stores English
/// ones ("Ho Chi Minh City").
const List<List<String>> _cityAliases = <List<String>>[
  ['ho chi minh', 'hcm', 'hcmc', 'tphcm', 'sai gon', 'saigon'],
  ['ha noi', 'hanoi'],
  ['da nang', 'danang'],
];

/// Preferred locations that mean "anywhere".
const Set<String> _anywhere = <String>{
  'all vietnam',
  'viet nam',
  'vietnam',
  'toan quoc',
};

/// Whether a listing at [jobLocation] is in the student's [preferred]
/// location. No preference or "All Vietnam" accepts every listing; a
/// listing without a city (`null`, or only "Việt Nam") does not match a
/// specific city.
bool matchesPreferredLocation(String? jobLocation, String? preferred) {
  final want = foldText(preferred ?? '');
  if (want.isEmpty || _anywhere.contains(want)) return true;
  if (jobLocation == null) return false;

  final job = foldText(jobLocation);
  final aliases = _cityAliases.firstWhere(
    (spellings) => spellings.any((alias) => containsWords(want, alias)),
    orElse: () => [want],
  );
  return aliases.any((alias) => containsWords(job, alias));
}
