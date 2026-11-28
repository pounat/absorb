import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/readalong_appearance.dart';
void main() {
  test('appearance defaults preserve the existing reader', () {
    final p = ReadAlongAppearance.decode(null);
    expect(p.toMap(), {'size':20.0,'spacing':1.75,'family':'serif','theme':'dark'});
  });
  test('untrusted storage is bounded and cannot supply CSS', () {
    final p = ReadAlongAppearance.decode('{"size":999,"spacing":-1,"family":"url(https://evil)","theme":"<style>"}');
    expect(p.size,36); expect(p.spacing,1.2); expect(p.family,'serif'); expect(p.theme,'dark');
    for(final input in ['[]','null','{broken','{"size":"99","spacing":null}']) {
      expect(ReadAlongAppearance.decode(input).toMap(),ReadAlongAppearance().toMap());
    }
    expect(ReadAlongAppearance.fromMap({'size':double.nan,'spacing':double.infinity}).toMap(),ReadAlongAppearance().toMap());
    final chosen=ReadAlongAppearance(size:28,spacing:2,family:'sans',theme:'sepia');
    expect(ReadAlongAppearance.decode(chosen.encode()).toMap(),chosen.toMap());
  });
}
