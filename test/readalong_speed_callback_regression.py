from pathlib import Path
import os, shutil, subprocess, sys, tempfile
s=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
reader=(s/'lib/widgets/bookorbit_readalong_web.dart').read_text()
sheet=(s/'lib/widgets/card_buttons.dart').read_text()
def body(text,signature):
 start=text.index(signature); brace=text.index('{',start); depth=1;i=brace+1
 while depth:
  if text[i]=='{':depth+=1
  if text[i]=='}':depth-=1
  i+=1
 return text[start:i]
getters='\n'.join(body(reader,'bool get '+n) for n in ['active','playingThisBook'])
methods='\n'.join(body(sheet,n) for n in ['void _setSpeed(double v)', 'Future<void> _addCurrentAsPreset()', 'Future<void> _removePreset(double value)'])
# Extract the exact reader callback predicate, if present; the held candidate
# has no callback authorization and is intentionally run as an unguarded sheet.
import re
match=re.search(r'bool canChangeSpeed\(\) => (.*?);',reader)
predicate=match.group(1) if match else 'true'
code='''class BookOrbitApiService {String readAlongOwnerKey; bool readAlongOwnerActive=true; BookOrbitApiService(this.readAlongOwnerKey);}
class AuthProvider {dynamic apiService; AuthProvider(this.apiService);}
class Context {AuthProvider auth; Context(this.auth); T read<T>()=>auth as T;}
class Player {dynamic currentApi; String currentItemId='reader'; bool hasBook=true; bool paused=true; double speed=1; int mutations=0; void setSpeed(double v){speed=v;mutations++;}}
class Widget {String? itemId='reader'; Player player; bool Function()? canChangeSpeed; Widget(this.player);}
class PlayerSettings {static List<String> writes=[]; static void setBookSpeed(String id,double v){writes.add('$id:$v');} static void notifySettingsChanged(){writes.add('notify');} static Future<void> setSpeedPresets(List<double> v) async {writes.add('presets:$v');}}
class ChromecastService {void setSpeed(double v){throw 'unexpected cast';}}
class Harness {
 bool mounted=true, retired=false; bool _isCasting=false; double _speed=1; List<double> _presets=[1,1.5,2]; final Player player=Player(); late Widget widget=Widget(player); late BookOrbitApiService api=BookOrbitApiService('owner-a'); String owner='owner-a'; late Context context=Context(AuthProvider(api)); void setState(void Function() f)=>f();
 GETTERS
 METHODS
 void open({bool guarded=true}) {player.currentApi=api; final speedOwner=owner; final speedItemId=widget.itemId; if(guarded)widget.canChangeSpeed=()=>PREDICATE;}
}
void check(bool v,String why){if(!v)throw StateError(why);}
Future<void> main() async {
 for(final mode in ['different-book','retired-account','retired-view','unmounted','no-book','owner-key-changed','retired-account-returned','reader-item-replaced']){
  final h=Harness()..open();PlayerSettings.writes.clear();final callback=h._setSpeed; final add=h._addCurrentAsPreset; final remove=h._removePreset;
  switch(mode){
   case 'reader-item-replaced':h.widget.itemId='other';h.player.currentItemId='other';break;
   case 'different-book':h.player.currentItemId='other';break;
   case 'retired-account':h.api.readAlongOwnerActive=false;final n=BookOrbitApiService('owner-b');h.context.auth.apiService=n;h.player.currentApi=n;break;
   case 'retired-view':h.retired=true;break;
   case 'unmounted':h.mounted=false;break;
   case 'no-book':h.player.hasBook=false;break;
   case 'owner-key-changed':h.owner='owner-b';break;
   case 'retired-account-returned':h.api.readAlongOwnerActive=false;final n=BookOrbitApiService('owner-a');h.context.auth.apiService=n;h.player.currentApi=n;break;
  }
  for(final speed in [2.0,2.15,2.2])callback(speed);
  h._speed=2.15;await add();await remove(1.5);
  check(h.player.mutations==0 && PlayerSettings.writes.isEmpty,'stale $mode mutated playback or preferences: ${h.player.mutations} / ${PlayerSettings.writes}');
  print('PASS stale $mode: retained drag/preset callbacks have zero player/book/preset writes');
 }
 for(final guarded in [true,false]){
  final h=Harness()..open(guarded:guarded);PlayerSettings.writes.clear();h._setSpeed(2.15);await h._addCurrentAsPreset();await h._removePreset(1.5);
  check(h.player.speed==2.15 && h.player.paused && h.player.mutations==1,'valid paused speed');
  check(PlayerSettings.writes.length==4,'valid book+notification+add+remove');
  print('PASS ${guarded?'reader valid paused owner':'null guard ordinary player'} speed/book/custom preset add/remove');
 }
 final h=Harness()..open(guarded:false);h.player.hasBook=false;PlayerSettings.writes.clear();h._setSpeed(1.5);check(h.player.mutations==0 && PlayerSettings.writes.first=='reader:1.5','ordinary inactive card persistence');print('PASS null guard inactive regular card still saves speed');
}
'''.replace('GETTERS',getters).replace('METHODS',methods).replace('PREDICATE',predicate)
dart = os.environ.get('DART') or shutil.which('dart')
if not dart:
 raise SystemExit('Dart SDK required: put dart on PATH or set DART')
with tempfile.TemporaryDirectory(prefix='readalong-speed-') as directory:
 p=Path(directory)/'exact-production-callback-regression.dart';p.write_text(code)
 result=subprocess.run([dart,str(p)],capture_output=True,text=True)
 print(result.stdout,end='');print(result.stderr,end='');sys.exit(result.returncode)
