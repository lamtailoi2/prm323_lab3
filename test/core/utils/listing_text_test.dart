import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/listing_text.dart';

void main() {
  group('plainListingText', () {
    test('drops heading markers and collapses blank lines', () {
      expect(
        plainListingText(
          '## Job Purpose\n\n\n\n- Thực tập sinh (TTS) Hoạch định\n'
          '* Hỗ trợ nhóm\n\n### Requirements ##\nFlutter',
        ),
        'Job Purpose\n\n• Thực tập sinh (TTS) Hoạch định\n• Hỗ trợ nhóm\n\n'
        'Requirements\nFlutter',
      );
    });

    test('removes bold markers and horizontal rules', () {
      expect(
        plainListingText('**Benefits**\n---\n__Laptop__ provided\r\n***'),
        'Benefits\nLaptop provided',
      );
    });

    test('leaves plain text, C++ and C# untouched', () {
      const text = 'Job Description: Design and develop C++ and C# services.';
      expect(plainListingText(text), text);
    });

    test('a text made only of markers becomes empty', () {
      expect(plainListingText('---\n\n## \n'), '');
    });

    test('#hashtag lines are not headings', () {
      expect(
        plainListingText('#Hiring Flutter interns'),
        '#Hiring Flutter interns',
      );
    });
  });

  group('plainListingItem', () {
    test('removes a leading bullet and bold markers', () {
      expect(plainListingItem('- **REST API** basics'), 'REST API basics');
      expect(plainListingItem('• Git'), 'Git');
      expect(plainListingItem('  Teamwork  '), 'Teamwork');
    });
  });

  test('a heading that ends in C# keeps the hash', () {
    expect(
      plainListingText('## Skills: C#\n- Flutter'),
      'Skills: C#\n• Flutter',
    );
    expect(plainListingText('### .NET / C#'), '.NET / C#');
    expect(plainListingText('## Requirements ##'), 'Requirements');
    expect(plainListingText('#hashtag'), '#hashtag');
  });
}
