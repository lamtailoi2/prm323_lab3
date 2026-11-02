/// Lower-cases [value], removes Vietnamese diacritics and turns every run
/// of other characters into one space, so "Thành phố Hồ Chí Minh" and
/// "Ho Chi Minh City" can be compared word by word.
String foldText(String value) {
  return removeDiacritics(value).replaceAll(RegExp('[^a-z0-9]+'), ' ').trim();
}

/// Lower-cases [value] and removes Vietnamese diacritics but keeps every
/// other character, so a search for `ha noi` finds `Hà Nội` while `C#` and
/// `C++` stay distinct from `C`.
String removeDiacritics(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[̀-ͯ]'), '')
      .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd');
}

/// Whether [phrase] (already folded) appears in [text] (already folded) as
/// whole words.
bool containsWords(String text, String phrase) {
  if (phrase.isEmpty) return false;
  return RegExp('(?<![a-z0-9])${RegExp.escape(phrase)}(?![a-z0-9])')
      .hasMatch(text);
}
