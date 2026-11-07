import 'package:firebase_remote_config/firebase_remote_config.dart'
    show ValueSource;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/services/remote_config_service.dart';

void main() {
  test('every key has a typed in-app default in the JSON asset', () async {
    final defaults = await loadRemoteConfigDefaults(rootBundle);

    expect(defaults[RemoteConfigKeys.homeRecommendedLimit], isA<int>());
    expect(
      defaults[RemoteConfigKeys.homeRecommendedLimit] as int,
      greaterThan(0),
    );
    expect(defaults[RemoteConfigKeys.cvMatchEnabled], isA<bool>());
  });

  test('sources use the stable names the demo screen renders', () {
    expect(
      FirebaseRemoteConfigService.sourceName(ValueSource.valueRemote),
      'remote',
    );
    expect(
      FirebaseRemoteConfigService.sourceName(ValueSource.valueDefault),
      'default',
    );
    expect(
      FirebaseRemoteConfigService.sourceName(ValueSource.valueStatic),
      'static',
    );
  });

  test('a non-object JSON file is rejected', () async {
    final bundle = _StringBundle('[1, 2]');
    expect(loadRemoteConfigDefaults(bundle), throwsFormatException);
  });
}

class _StringBundle extends CachingAssetBundle {
  _StringBundle(this.content);

  final String content;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(content.codeUnits));
}
