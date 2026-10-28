/// Lower-cases [value], removes Vietnamese diacritics and turns every run
/// of other characters into one space, so "Thành phố Hồ Chí Minh" and
/// "Ho Chi Minh City" can be compared word by word.
String foldText(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[̀-ͯ]'), '')
      .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd')
      .replaceAll(RegExp('[^a-z0-9]+'), ' ')
      .trim();
}

/// Whether [phrase] (already folded) appears in [text] (already folded) as
/// whole words.
bool containsWords(String text, String phrase) {
  if (phrase.isEmpty) return false;
  return RegExp('(?<![a-z0-9])${RegExp.escape(phrase)}(?![a-z0-9])')
      .hasMatch(text);
}
