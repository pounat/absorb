import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/auth_tokens.dart';
import '../../lib/services/browser_adapter.dart';
void main(){
 test('public labels scope browser APIs without exposing cookie credentials',(){
  for(final prefix in ['', 'bookorbit/']){
   final route='/${prefix}sessions/${'A'*24}';
   final tokens=AuthTokens.fromResponse({'user':{'accessToken':'browser-cookie','refreshToken':'browser-cookie'},'webSessionRoute':route},browser:true);
   expect(BrowserAdapter.isSessionLabel(tokens.token!),isTrue);
   expect(BrowserAdapter.sessionBase(Uri.parse('https://client.example.invalid/absorb/'),tokens.token!), 'https://client.example.invalid$route');
  }
 });
 test('malformed or external public labels cannot change browser origin',(){
  for(final route in ['//other.example.invalid','/sessions/short','/bookorbit/sessions/${'A'*24}?token=bad','/sessions/${'A'*24}/extra']){
   expect(()=>AuthTokens.fromResponse({'user':{'accessToken':'browser-cookie','refreshToken':'browser-cookie'},'webSessionRoute':route},browser:true),throwsFormatException);
  }
 });
}
