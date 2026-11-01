/// Formats the allowance text Google Jobs returns for the internship cards.
///
/// SerpAPI copies Google's wording, so the same period appears as
/// `a month`, `per month`, `/month` or `monthly`. The Lab 2 card uses the
/// compact `VND / mo` form (G-17). Nothing is invented: text that is already
/// meaningful (hourly pay, "Negotiable", a range) is kept, only the period
/// word is normalised.
String formatAllowance(String? raw, {String undisclosed = 'Not disclosed'}) {
  final text = raw?.trim();
  if (text == null || text.isEmpty) return undisclosed;

  var normalized = text.replaceAll(RegExp(r'\s+'), ' ');
  normalized = normalized.replaceAll(
    RegExp(r'\s*(?:/|per\s+|a\s+|an\s+)?month(?:ly)?\b', caseSensitive: false),
    ' / mo',
  );
  normalized = normalized.replaceAll(
    RegExp(r'\s*/\s*mo\b', caseSensitive: false),
    ' / mo',
  );
  return normalized.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}

/// Words that introduce pay in Vietnamese and English listings.
final RegExp _payWord = RegExp(
  r'(mức lương|lương|thu nhập|trợ cấp|phụ cấp|thù lao|allowance|salary|'
  r'stipend)',
  caseSensitive: false,
);

final RegExp _negotiable = RegExp(
  r'(thỏa thuận|thoả thuận|negotiable|thương lượng)',
  caseSensitive: false,
);

/// One amount or range: optional qualifier and currency, a number with an
/// optional multiplier (`triệu`, `tr`, `million`, `M`, `K`), an optional
/// second number after `-` / `->` / `đến` / `to`, and an optional currency,
/// which may follow the number without a space ("7,000,000VND").
final RegExp _money = RegExp(
  r'(?<q>lên đến|up to|tối đa|đến|tới|khoảng|about|approximately|từ|from|~)?'
  r'\s*(?<cur1>\$|usd)?\s*'
  r'(?<a>\d+(?:[.,]\d+)*)(?![.,]?\d)'
  r'(?:\s*(?<u1>triệu|tr|million|m|k)(?!\p{L}))?'
  r'(?:\s*(?:->|→|-|–|—|~|đến|tới|to)\s*'
  r'(?<b>\d+(?:[.,]\d+)*)(?![.,]?\d)'
  r'(?:\s*(?<u2>triệu|tr|million|m|k)(?!\p{L}))?)?'
  r'\s*(?<cur2>vnd|vnđ|đồng|usd|\$)?',
  caseSensitive: false,
  unicode: true,
);

/// Allowances that are not the pay itself ("Lunch allowance", "phụ cấp ăn
/// trưa", "Home Office Support Allowance").
final RegExp _otherAllowanceBefore = RegExp(
  r'(meal|lunch|parking|phone|transport|travel|home office|internet|'
  r'laptop|housing|petrol)[\w\s]{0,12}$',
  caseSensitive: false,
);
final RegExp _otherAllowanceAfter = RegExp(
  r'^\s*(ăn|gửi xe|xăng|điện thoại|đi lại|đt\b)',
  caseSensitive: false,
);

final RegExp _monthly = RegExp(r'(tháng|month|/\s*th\b)', caseSensitive: false);

final RegExp _grouped = RegExp(r'^\d{1,3}(?:[.,]\d{3})+$');

/// How far after a pay word an amount may start (characters).
const int _payWindow = 60;

/// Plausible monthly ranges; anything else (e.g. "Lương tháng 13",
/// "100% salary") is not an allowance.
const int _minVnd = 100000;
const int _maxVnd = 200000000;
const int _minUsd = 50;
const int _maxUsd = 10000;

/// Reads the allowance from a listing's free text. Google Jobs leaves
/// `detected_extensions.salary` empty for Vietnamese listings, but many
/// descriptions state the pay ("Thu nhập: Khoảng 2-3 triệu đồng /tháng",
/// "Internship allowance: 10,000,000 VND/month").
///
/// Returns display text such as `About 2,000,000–3,000,000 VND / mo` or
/// `Negotiable`, or `null` when the text gives no amount and does not say
/// the pay is negotiable. Vague phrases ("Attractive allowance") stay `null`
/// so the card shows "Not disclosed" instead of an invented value.
String? allowanceFromText(String text) {
  var negotiable = false;
  for (final word in _payWord.allMatches(text)) {
    final before = text.substring(
      (word.start - 25).clamp(0, text.length),
      word.start,
    );
    final end = (word.end + _payWindow).clamp(0, text.length);
    final window = text.substring(word.end, end);
    if (_otherAllowanceBefore.hasMatch(before) ||
        _otherAllowanceAfter.hasMatch(window)) {
      continue;
    }
    for (final match in _money.allMatches(window)) {
      final amount = _describe(match, window);
      if (amount != null) return amount;
    }
    if (_negotiable.hasMatch(window)) negotiable = true;
  }
  return negotiable ? 'Negotiable' : null;
}

String? _describe(RegExpMatch match, String window) {
  final secondUnit = match.namedGroup('u2');
  final usd = [
    match.namedGroup('cur1'),
    match.namedGroup('cur2'),
  ].any((currency) => currency != null && !_isVnd(currency));
  final low = _amount(
    match.namedGroup('a')!,
    match.namedGroup('u1') ?? secondUnit,
  );
  final second = match.namedGroup('b');
  final high = second == null ? null : _amount(second, secondUnit);
  if (low == null || !_plausible(low, usd)) return null;
  if (high != null && (!_plausible(high, usd) || high < low)) return null;

  final isRange = high != null && high != low;
  final qualifier = switch (match.namedGroup('q')?.toLowerCase()) {
    'khoảng' || 'about' || 'approximately' || '~' => 'About ',
    // "Từ 5 – 10 triệu" is just a range: From / Up to add nothing to it.
    _ when isRange => '',
    'lên đến' || 'up to' || 'tối đa' || 'đến' || 'tới' => 'Up to ',
    'từ' || 'from' => 'From ',
    _ => '',
  };
  String money(int value) => usd ? '\$${_group(value)}' : _group(value);
  final range = isRange ? '${money(low)}–${money(high)}' : money(low);
  final after = window.substring(
    match.start,
    (match.end + 20).clamp(0, window.length),
  );
  final period = _monthly.hasMatch(after) ? ' / mo' : '';
  return '$qualifier$range${usd ? '' : ' VND'}$period';
}

bool _isVnd(String currency) =>
    const {'vnd', 'vnđ', 'đồng'}.contains(currency.toLowerCase());

/// Grouped numbers ("2.300.000", "10,000,000") are absolute; otherwise the
/// multiplier applies ("3M", "2,5 triệu", "1000K").
int? _amount(String digits, String? unit) {
  if (_grouped.hasMatch(digits)) {
    return int.parse(digits.replaceAll(RegExp('[.,]'), ''));
  }
  final value = double.tryParse(digits.replaceAll(',', '.'));
  if (value == null) return null;
  final multiplier = switch (unit?.toLowerCase()) {
    'triệu' || 'tr' || 'million' || 'm' => 1000000,
    'k' => 1000,
    _ => 1,
  };
  return (value * multiplier).round();
}

bool _plausible(int value, bool usd) => usd
    ? value >= _minUsd && value <= _maxUsd
    : value >= _minVnd && value <= _maxVnd;

String _group(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);
