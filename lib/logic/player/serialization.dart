import 'dart:convert';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sweyer/sweyer.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Interface to manage serialization.
///
/// [R] denotes type that is returned from [read] method.
/// [S] denotes type that has to be provided to the [save] method.
abstract class JsonSerializer<R, S> {
  const JsonSerializer();

  String get fileName;

  /// Value that will be written in [init] method.
  S get initialValue;

  /// Create file json if it does not exists or of it is empty then write to it empty array.
  Future<void> init() async {
    final file = await getFile();
    if (!file.existsSync()) {
      await file.create();
      await file.writeAsString(jsonEncode(initialValue));
    } else if (await file.readAsString() == '') {
      await file.writeAsString(jsonEncode(initialValue));
    }
  }

  Future<File> getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  /// Reads json and returns decoded data.
  Future<R> read();

  /// Serializes provided data into json.
  Future<void> save(S data);
}

/// The type for [IntListSerializer].
typedef IntSerializerType = JsonSerializer<List<int>, List<int>>;

/// Serializes a list of integers.
class IntListSerializer extends JsonSerializer<List<int>, List<int>> {
  const IntListSerializer(this.fileName);

  @override
  final String fileName;

  @override
  List<int> get initialValue => [];

  @override
  Future<List<int>> read() async {
    try {
      final file = await getFile();
      final jsonContent = await file.readAsString();
      return jsonDecode(jsonContent).cast<int>();
    } catch (ex, stack) {
      FirebaseCrashlytics.instance.recordError(
        ex,
        stack,
        reason: 'in IntListSerializer.read, fileName: $fileName',
      );
      ShowFunctions.instance.showError(
        errorDetails: buildErrorReport(ex, stack),
      );
      debugPrint('$fileName: error reading integer list json, setting to empty list');
      return [];
    }
  }

  @override
  Future<void> save(List<int> data) async {
    final file = await getFile();
    await file.writeAsString(jsonEncode(data));
    // debugPrint('$fileName: json saved');
  }
}

/// Item for [QueueSerializer].
@visibleForTesting
class SerializedQueueItem {
  const SerializedQueueItem({
    required this.id,
    required this.duplicationIndex,
    required this.originEntry,
  });

  final int id;
  final int? duplicationIndex;
  final SongOriginEntry? originEntry;

  factory SerializedQueueItem.fromMap(Map map) {
    final rawOriginEntry = map['origin'];
    return SerializedQueueItem(
      id: map['id'],
      duplicationIndex: map['duplicationIndex'],
      originEntry: rawOriginEntry == null ? null : SongOriginEntry.fromMap(rawOriginEntry),
    );
  }
  Map<String, dynamic> toMap() => {
        'id': id,
        if (duplicationIndex != null) 'duplicationIndex': duplicationIndex,
        if (originEntry != null) 'origin': originEntry!.toMap(),
      };
}

/// The type for [QueueSerializer].
typedef QueueSerializerType = JsonSerializer<List<SerializedQueueItem>, List<Song>>;

/// Used to serialize queue.
///
/// Saves only songs ids, so you have to search indexes in 'all' queue to restore.
class QueueSerializer extends QueueSerializerType {
  const QueueSerializer(this.fileName);

  @override
  final String fileName;

  @override
  List<Song> get initialValue => [];

  /// Returns a list of song ids.
  @override
  Future<List<SerializedQueueItem>> read() async {
    try {
      final file = await getFile();
      final jsonContent = await file.readAsString();
      final list = jsonDecode(jsonContent) as List;
      if (list.isNotEmpty) {
        // Initially the queue was saved as list of ids.
        // This ensures there will be no errors in case someone migrates from
        // the old version.
        //
        // Changed in 1.0.4
        if (list[0] is int) {
          return [];
        }
      }
      return list.map((el) => SerializedQueueItem.fromMap(el)).toList();
    } catch (ex, stack) {
      FirebaseCrashlytics.instance.recordError(
        ex,
        stack,
        reason: 'in QueueSerializer.read, fileName: $fileName',
      );
      ShowFunctions.instance.showError(
        errorDetails: buildErrorReport(ex, stack),
      );
      debugPrint('$fileName: error reading songs json, setting to empty songs list');
      return [];
    }
  }

  @override
  Future<void> save(List<Song> data) async {
    final file = await getFile();
    final json = jsonEncode(data
        .map((song) => SerializedQueueItem(
              id: song.id,
              duplicationIndex: song.duplicationIndex,
              originEntry: song.origin?.toSongOriginEntry(),
            ).toMap())
        .toList());
    await file.writeAsString(json);
    // debugPrint('$fileName: json saved');
  }
}

/// The type for [IdMapSerializer].
typedef IdMapSerializerType = JsonSerializer<IdMap, IdMap>;

/// Used to serialize song id map.
class IdMapSerializer extends IdMapSerializerType {
  const IdMapSerializer();

  @override
  String get fileName => 'id_map.json';

  @override
  IdMap get initialValue => {};

  @override
  Future<IdMap> read() async {
    try {
      final file = await getFile();
      final jsonContent = await file.readAsString();
      final json = jsonDecode(jsonContent) as Map;
      final IdMap idMap = {};
      for (final entry in json.entries) {
        final IdMapKey? key;
        final decodedKey = jsonDecode(entry.key);
        // Initially the id map was saved as just `Map<String, int>` where:
        // key was negative song id,
        // value was the source positive id
        //
        // This ensures there will be no errors in case someone migrates from
        // the old version.
        //
        // Changed in 1.0.4
        if (decodedKey is String) {
          key = IdMapKey(id: int.parse(decodedKey), originEntry: null);
        } else {
          key = IdMapKey.fromMap(decodedKey as Map);
        }
        if (key != null) {
          idMap[key] = entry.value as int;
        }
      }
      return idMap;
    } catch (ex, stack) {
      FirebaseCrashlytics.instance.recordError(
        ex,
        stack,
        reason: 'in IdMapSerializer.read, fileName: $fileName',
      );
      ShowFunctions.instance.showError(
        errorDetails: buildErrorReport(ex, stack),
      );
      debugPrint('$fileName: error reading id map json, setting to empty map');
      return {};
    }
  }

  /// Serializes provided map as id map.
  /// Used on dart side to saved cleared map, in other cases used on native.
  @override
  Future<void> save(IdMap data) async {
    final file = await getFile();
    await file.writeAsString(jsonEncode(data.map(
      (key, value) => MapEntry(jsonEncode(key.toMap()), value),
    )));
    // debugPrint('$fileName: json saved');
  }
}
