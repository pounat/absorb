import 'dart:async';
import '../../lib/web_playback/web_playback_session.dart';
void check(bool value, String message) { if (!value) throw StateError(message); }
Future<void> main() async {
 var now = Duration.zero; var reads=0; final writes=<List<num>>[];
 final s=WebPlaybackSession(nativeSessionSync:true,clock:()=>now, readProgress:() async {reads++; throw StateError('unused slow GET');}, send:(p,t) async {writes.add([p,t]);return 200;});
 s.sample(0,audible:true);
 for(var i=1;i<=60;i++){now=Duration(seconds:i);s.sample(i.toDouble(),audible:true);await s.checkpoint();}
 check(reads==0,'periodic sync must not GET progress');
 check(writes.map((w)=>w[0]).join(',')=='20.0,30.0,40.0,50.0,60.0','first20 then10: $writes');
 check(writes.map((w)=>w[1]).join(',')=='20,10,10,10,10','audible increments: $writes');
 print('PASS first20 then10 direct POST, zero recurring GET');
 now=Duration.zero; final failed=<List<num>>[];var warnings=0;
 final f=WebPlaybackSession(nativeSessionSync:true,clock:()=>now,onWarning:()=>warnings++,send:(p,t) async {failed.add([p,t]);return failed.length<=4?502:200;});
 f.sample(0,audible:true);
 for(var i=1;i<=60;i++){now=Duration(seconds:i);f.sample(i.toDouble(),audible:true);await f.checkpoint();}
 check(!f.recoveryRequired,'transient failure must not require recovery');
 check(failed.length==5 && failed[0][1]==20 && failed.skip(1).every((w)=>w[1]==10),'consume each increment once: $failed');
 check(warnings==1 && f.consecutiveFailures==0,'warn four, success clears failures');
 print('PASS transient POST continues fresh accrual; warn four; no replay');
 for(final status in <int?>[401,403,404,409]) {
  now=Duration.zero;var n=0;
  final a=WebPlaybackSession(nativeSessionSync:true,clock:()=>now,send:(p,t) async {n++;return status;});
  a.sample(90,audible:true);now=const Duration(seconds:20);a.sample(110,audible:true);await a.checkpoint();
  now=const Duration(seconds:100);a.sample(190,audible:true);await a.checkpoint(force:true);
  check(n==1 && a.recoveryRequired,'quarantine exact denial $status');
  var deniedCloses=0;await a.close(()async{deniedCloses++;});
  check(deniedCloses==0,'quarantined write authority cannot close $status');
 }
 print('PASS auth/expiry/stale ownership quarantines writes');
 // The timeout is test-injected, while transport completion remains real.
 now=Duration.zero;final gate=Completer<int?>();final held=<List<num>>[];
 final h=WebPlaybackSession(nativeSessionSync:true,syncTimeout:const Duration(milliseconds:20),clock:()=>now,send:(p,t){held.add([p,t]);return held.length==1?gate.future:Future.value(200);});
 h.sample(0,audible:true);now=const Duration(seconds:20);h.sample(20,audible:true);final flight=h.checkpoint();
 now=const Duration(seconds:21);h.sample(21,audible:false);await h.checkpoint(force:true);
 await Future<void>.delayed(const Duration(milliseconds:30));
 now=const Duration(seconds:30);h.sample(500,audible:false);await h.checkpoint(force:true);
 check(held.length==1 && !h.recoveryRequired,'timeout cannot release real transport or pause authority');
 gate.complete(200);await flight;check(held.length==1,'late ack cannot drain queued uncertain delta');
 h.sample(500,audible:true);now=const Duration(seconds:40);h.sample(510,audible:true);await h.checkpoint();
 check(held.length==2 && held[1][0]==510 && held[1][1]==10,'fresh accrual only after uncertainty: $held');
 print('PASS held POST timeout no overlap, coalescing, late-ack fence, fresh next increment');
 now=Duration.zero;final oldGate=Completer<int?>();var oldWrites=0;var closes=0;var notices=0;
 final old=WebPlaybackSession(nativeSessionSync:true,clock:()=>now,onWarning:()=>notices++,send:(p,t){oldWrites++;return oldGate.future;});
 old.sample(0,audible:true);now=const Duration(seconds:20);old.sample(20,audible:true);final ow=old.checkpoint();
 await old.checkpoint(force:true);final closing=old.close(()async{closes++;});old.retire();oldGate.complete(403);await Future.wait([ow,closing]);
 await old.checkpoint(force:true);check(oldWrites==1 && closes==0 && notices==0,'account switch retires queued writes/closes/notices');
 print('PASS late retired account acknowledgment is inert');
 now=Duration.zero;final counts=<int>[];final p=WebPlaybackSession(nativeSessionSync:true,clock:()=>now,send:(x,t)async{counts.add(t);return 200;});
 p.sample(10,audible:true,rate:2);now=const Duration(seconds:5);p.sample(20,audible:false,rate:2);await p.checkpoint(force:true);
 now=const Duration(seconds:100);p.sample(800,audible:false);await p.checkpoint(force:true);p.sample(800,audible:true);
 now=const Duration(seconds:200);p.sample(800,audible:false);await p.checkpoint(force:true);
 check(counts.join(',')=='5,0,0','seek/pause/buffer/rate cannot count wall or seek distance $counts');
 check(WebPlaybackSession.resumePosition(100,{'currentTime':40})==40,'authoritative server rewind starts behind local');
 final r=WebPlaybackSession(nativeSessionSync:true,clock:()=>now,send:(p,t)async=>200);r.sample(900,audible:false);
 check(await r.recoveryPosition(readProgress:()async=>{'currentTime':40},readSession:()async=>{'id':'session-owner'})==40,'fresh recovery server wins');
 var threw=false;try{await r.recoveryPosition(readProgress:()async=>throw StateError('offline'),readSession:()async=>null);}catch(_){threw=true;}
 check(threw,'failed initial/recovery read must not become zero');
 print('PASS pause seek rate buffering and authoritative rewind/read failure');
 now=Duration.zero;final uncertain=Completer<int?>();final events=<String>[];
 final c=WebPlaybackSession(nativeSessionSync:true,clock:()=>now,send:(p,t){events.add('sync:$t');return uncertain.future;});
 c.sample(0,audible:true);now=const Duration(seconds:20);c.sample(20,audible:true);final cw=c.checkpoint();final cc=c.close(()async{events.add('empty-close');});uncertain.complete(null);await Future.wait([cw,cc]);
 check(events.join(',')=='sync:20,empty-close','close must never replay uncertain delta');
 print('PASS ordered empty close never replays uncertain delta');
}
