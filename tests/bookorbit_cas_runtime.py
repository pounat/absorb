#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Run exact production methods in a dependency-free pinned Dart VM fixture."""
from pathlib import Path
import subprocess, tempfile, os
root=Path(__file__).resolve().parents[1]
s=(root/'lib/services/bookorbit_api_service.dart').read_text()
read=s[s.index('  Future<Map<String, dynamic>?> _playbackState('):s.index('  ({String? cfi',s.index('  Future<Map<String, dynamic>?> _playbackState('))]
write=s[s.index('  Future<int> _putPosition('):s.index('\n  }',s.index('  Future<int> _putPosition('))+4]
helper=s[s.index('int bookOrbitWebRevision('):s.index('\n}\n',s.index('int bookOrbitWebRevision('))+3]
header="import 'dart:convert';\n"+helper
fixture=r'''
const kIsWeb=true;
void debugPrint(Object? o){}
class _BoHttpError implements Exception {final int status;final String message;_BoHttpError(this.status,[this.message='']);}
class BookOrbitMapper { static ({String assetId,int positionMs})? trackPosition(dynamic m,double s)=>(assetId:'audio',positionMs:(s*1000).round()); }
class Probe {
 dynamic input; dynamic ack; int gets=0,puts=0; final _revisions=<String,int>{};
 Probe(this.input,this.ack);
 String _key(String s)=>s;
 Future<dynamic> _boGet(String p)async{gets++;if(input is Exception)throw input;return input;}
 Future<dynamic> _boPut(String p,Object b)async{puts++;return ack;}
 Future<void> _backOnContinue(String s)async{}
 Future<Map<String,dynamic>?> _manifest(String s,{bool fresh=false})async=>{'revision':'manifest'};
 Future<int> _putNarrationPosition(String s,double d)async=>200;
 String _uuid()=>'unique-operation';String _iso(DateTime d)=>d.toIso8601String();
'''
tests=r'''
}
Future<void> main()async {
 int count=0;
 void check(bool b,String label){if(!b)throw StateError(label);count++;}
 final invalid=<dynamic>[{'revision':1.75},{},[],{'revision':null},{'revision':-1},{'revision':'1'},{'revision':true},{'revision':double.nan},{'revision':double.infinity},{'revision':9007199254740992}];
 for(final value in invalid){final p=Probe(value,{'revision':2});p._revisions['1']=8;bool failed=false;try{await p._playbackState('1');}catch(_){failed=true;}check(failed,'malformed read accepted: $value');check(!p._revisions.containsKey('1'),'malformed read retained cache');check(p.puts==0,'read wrote');}
 for(final rev in [0,1,1.0,9007199254740991]){final p=Probe({'revision':rev},{'revision':2});await p._playbackState('1');check(p._revisions['1']==rev,'exact integer rejected');}
 final absent=Probe(null,{'revision':1});check(await absent._playbackState('1')==null,'native null state');check(absent._revisions['1']==0,'native null must initialize CAS0');check(await absent._putPosition('1',2)==200&&absent._revisions['1']==1,'new book CAS0 -> 1');
 final missing=Probe(_BoHttpError(404),{'revision':1});bool failed=false;try{await missing._playbackState('1');}catch(_){failed=true;}check(failed&&!missing._revisions.containsKey('1'),'404 is unavailable resource, not no history');
 for(final value in [...invalid,null,{'revision':0},{'revision':1},{'revision':3}]){final p=Probe({'revision':1},value);bool failed=false;try{await p._putPosition('1',12);}catch(_){failed=true;}check(failed,'malformed/wrong write ack accepted: $value');check(p.puts==1,'uncertain write retried');check(!p._revisions.containsKey('1'),'uncertain ack cached revision');}
 final good=Probe({'revision':1},{'revision':2});check(await good._putPosition('1',12)==200&&good._revisions['1']==2,'normal update');
 final badInitial=Probe([],{'revision':1});try{await badInitial._putPosition('1',0);}catch(_){}check(badInitial.puts==0,'failed read must never zero-write');
 print('PASS $count exact-production CAS assertions');
}
'''
with tempfile.TemporaryDirectory(dir=os.environ['TMPDIR']) as d:
 p=Path(d)/'probe.dart';p.write_text(header+fixture+read+write+tests)
 sdk=os.environ.get('DART', 'dart')
 raise SystemExit(subprocess.run([sdk,str(p)]).returncode)
