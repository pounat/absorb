// import 'dart:convert';

// import 'package:flutter_chrome_cast/entities/queue_item.dart';
// import 'package:flutter_chrome_cast/common/repeat_mode.dart';
// export 'package:flutter_chrome_cast/entities/queue_item.dart';
// export 'package:flutter_chrome_cast/common/repeat_mode.dart';

// class GoogleCastMediaQueueData {
//   final String? id;
//   final String? name;
//   final String? description;
//   final GoogleCastMediaRepeatMode? repeatMode;

//   /// if you will run LOAD command, you will
//   ///  prefer put only one item
//   /// in queue with id equals 0 and
//   /// then you can use QUEUE_INSERT
//   ///  command to add items to queue
//   final List<GoogleCastQueueItem>? items;
//   final int? startIndex;
//   final Duration? startTime;
//   GoogleCastMediaQueueData({
//     this.id,
//     this.name,
//     this.description,
//     this.repeatMode,
//     this.items,
//     this.startIndex,
//     this.startTime,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'description': description,
//       'repeatMode': repeatMode?.name,
//       'items': items?.map((x) => x.toMap()).toList(),
//       'startIndex': startIndex,
//       'startTime': startTime?.inSeconds,
//     };
//   }

//   factory GoogleCastMediaQueueData.fromMap(Map<String, dynamic> map) {
//     return GoogleCastMediaQueueData(
//       id: map['id'],
//       name: map['name'],
//       description: map['description'],
//       repeatMode: map['repeatMode'] != null
//           ? GoogleCastMediaRepeatMode.values[map['repeatMode']]
//           : null,
//       items: map['items'] != null
//           ? List<GoogleCastQueueItem>.from(
//               map['items']?.map((x) => GoogleCastQueueItem.fromMap(x)))
//           : null,
//       startIndex: map['startIndex']?.toInt(),
//       startTime: map['startTime'] != null
//           ? Duration(seconds: map['startTime']?.toInt() ?? 0)
//           : null,
//     );
//   }

//   String toJson() => json.encode(toMap());

//   factory GoogleCastMediaQueueData.fromJson(String source) =>
//       GoogleCastMediaQueueData.fromMap(json.decode(source));
// }
