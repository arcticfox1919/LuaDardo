import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

/// Read [stream] into a String.
///
/// Defaults to [utf8] if no [encoding] is given.
Future<String> readAsString(Stream<List<int>> stream, {Encoding encoding}) {
  encoding ??= utf8;
  return encoding.decodeStream(stream);
}

/// Read [stream] into a typed byte buffer.
///
/// When [maxLength] is specified and reached, the returned future completes
/// with an error.
///
/// [copy] controls whether the bytes the [stream] provides needs to be copied
/// (e.g. because the underlying list may get modified).
Future<Uint8List> readAsBytes(
    Stream<List<int>> stream, {
      int maxLength,
      bool copy = false,
    }) async {
  final bb = BytesBuffer();
  await for (List<int> next in stream) {
    bb.add(next);
    if (maxLength != null && maxLength < bb.length) {
      throw StateError('Max length reached: $maxLength bytes.');
    }
  }
  return bb.toBytes();
}

/// Read [stream] and slice the content into chunks with target/max length of
/// [sliceLength].
///
/// When [maxLength] is specified and reached, the returned Stream is closed
/// with and error.
///
/// [copy] controls whether the bytes the [stream] provides needs to be copied
/// (e.g. because the underlying list may get modified).
Stream<Uint8List> sliceStream(
    Stream<List<int>> stream,
    int sliceLength, {
      int maxLength,
      bool copy = false,
    }) async* {
  var total = 0;
  final buffer = <Uint8List>[];
  await for (List<int> bytes in stream) {
    var next = castBytes(bytes, copy: copy);

    total += next.length;
    if (maxLength != null && maxLength < total) {
      throw StateError('Max length reached: $maxLength bytes.');
    }

    buffer.add(next);
    int getBL() => buffer.fold<int>(0, (s, list) => s + list.length);

    while (getBL() >= sliceLength) {
      final bufferLength = getBL();
      Uint8List overflow;
      if (bufferLength > sliceLength) {
        final last = buffer.removeLast();
        final index = sliceLength - bufferLength + last.length;
        final missing = Uint8List(index);
        missing.setRange(0, index, last);
        buffer.add(missing);
        overflow = Uint8List(last.length - index);
        overflow.setRange(0, overflow.length, last, index);
      }

      final bb = BytesBuffer._fromChunks(List.from(buffer));
      buffer.clear();
      if (overflow != null) {
        buffer.add(overflow);
      }
      yield bb.toBytes();
    }
  }
  if (buffer.isNotEmpty) {
    final bb = BytesBuffer._fromChunks(buffer);
    yield bb.toBytes();
  }
}

/// Cast the list of bytes into a typed [Uint8List].
///
/// When [copy] is specified, the content will be copied even if the input
/// [bytes] are already Uint8List.
Uint8List castBytes(List<int> bytes, {bool copy = false}) {
  if (bytes is Uint8List) {
    if (copy) {
      final list = Uint8List(bytes.length);
      list.setRange(0, list.length, bytes);
      return list;
    } else {
      return bytes;
    }
  } else {
    return Uint8List.fromList(bytes);
  }
}

/// A class for concatenating byte arrays efficiently.
///
/// Allows for the incremental building of a byte array using add*() methods.
/// The arrays are concatenated to a single byte array only when [toBytes] is
/// called.
class BytesBuffer {
  final List<Uint8List> _chunks;
  final bool _copy;
  int _length = 0;

  BytesBuffer({bool copy = false})
      : _chunks = <Uint8List>[],
        _copy = copy;

  BytesBuffer._fromChunks(this._chunks, {bool copy = false}) : _copy = copy {
    _length = _chunks.fold<int>(0, (sum, c) => sum + c.length);
  }

  /// The total length of the buffer.
  int get length => _length;

  /// Add a byte array to the buffer.
  ///
  /// Set [copy] to true if [bytes] need to be copied (e.g. the underlying
  /// buffer will be modified.)
  void add(List<int> bytes, {bool copy}) {
    _chunks.add(castBytes(bytes, copy: copy ?? _copy));
    _length += bytes.length;
  }

  /// Add a single byte to the buffer.
  void addByte(int byte) {
    add([byte]);
  }

  /// Concatenate the byte arrays and return them as a single unit.
  Uint8List toBytes({bool copy}) {
    if (_chunks.length == 1 && !(copy ?? _copy)) {
      return _chunks.single;
    }
    final list = Uint8List(_length);
    var offset = 0;
    for (var i = 0; i < _chunks.length; i++) {
      final chunk = _chunks[i];
      list.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return list;
  }
}

/// A class for building byte arrays with a [BytesBuffer] and a fixed-length
/// work buffer.
///
/// Allows for the incremental building of a byte array using write*() methods.
/// The arrays are concatenated to a single byte array only when [toBytes] is
/// called.
class ByteDataWriter {
  int bufferLength;
  final Endian endian;
  final _bb = BytesBuffer();
  bool _dataEmpty = true;
  ByteData __data = ByteData(0);
  ByteData get _data => __data;
  set _data(ByteData data) {
    if (data == null) {
      _dataEmpty = true;
      __data = ByteData(0);
      return;
    }
    __data = data;
    _dataEmpty = false;
  }

  int _offset = 0;

  ByteDataWriter({this.bufferLength = 128, this.endian = Endian.big});

  void _flush() {
    if (!_dataEmpty) {
      if (_offset > 0) {
        _bb.add(_data.buffer.asUint8List(0, _offset));
      }
      _data = null;
      _offset = 0;
    }
  }

  void _init(int required) {
    if (_dataEmpty || _offset + required > _data.lengthInBytes) {
      _flush();
      _data = ByteData(bufferLength > required ? bufferLength : required);
    }
  }

  void write(List<int> bytes, {bool copy = false}) {
    // TODO: may add to current _data buffer
    _flush();
    _bb.add(bytes, copy: copy);
  }

  void writeFloat32(double value, [Endian endian]) {
    _init(4);
    _data.setFloat32(_offset, value, endian ?? this.endian);
    _offset += 4;
  }

  void writeFloat64(double value, [Endian endian]) {
    _init(8);
    _data.setFloat64(_offset, value, endian ?? this.endian);
    _offset += 8;
  }

  void writeInt8(int value) {
    _init(1);
    _data.setInt8(_offset, value);
    _offset++;
  }

  void writeInt16(int value, [Endian endian]) {
    _init(2);
    _data.setInt16(_offset, value, endian ?? this.endian);
    _offset += 2;
  }

  void writeInt32(int value, [Endian endian]) {
    _init(4);
    _data.setInt32(_offset, value, endian ?? this.endian);
    _offset += 4;
  }

  void writeInt64(int value, [Endian endian]) {
    _init(8);
    _data.setInt64(_offset, value, endian ?? this.endian);
    _offset += 8;
  }

  void writeInt(int byteLength, int value, [Endian endian]) {
    switch (byteLength) {
      case 1:
        writeInt8(value);
        break;
      case 2:
        writeInt16(value, endian);
        break;
      case 4:
        writeInt32(value, endian);
        break;
      case 8:
        writeInt64(value, endian);
        break;
      default:
        throw ArgumentError(
            'byteLength ($byteLength) must be one of [1, 2, 4, 8].');
    }
  }

  void writeUint8(int value) {
    _init(1);
    _data.setUint8(_offset, value);
    _offset++;
  }

  void writeUint16(int value, [Endian endian]) {
    _init(2);
    _data.setUint16(_offset, value, endian ?? this.endian);
    _offset += 2;
  }

  void writeUint32(int value, [Endian endian]) {
    _init(4);
    _data.setUint32(_offset, value, endian ?? this.endian);
    _offset += 4;
  }

  void writeUint64(int value, [Endian endian]) {
    _init(8);
    _data.setUint64(_offset, value, endian ?? this.endian);
    _offset += 8;
  }

  void writeUint(int byteLength, int value, [Endian endian]) {
    switch (byteLength) {
      case 1:
        writeUint8(value);
        break;
      case 2:
        writeUint16(value, endian);
        break;
      case 4:
        writeUint32(value, endian);
        break;
      case 8:
        writeUint64(value, endian);
        break;
      default:
        throw ArgumentError(
            'byteLength ($byteLength) must be one of [1, 2, 4, 8].');
    }
  }

  /// Concatenate the byte arrays and return them as a single unit.
  Uint8List toBytes() {
    _flush();
    return _bb.toBytes();
  }
}

/// A class for parsing byte arrays.
///
/// Allows incremental building of the input byte stream using the add() method.
/// The input arrays are concatenated as needed.
class ByteDataReader {
  final Endian endian;
  final _queue = DoubleLinkedQueue<Uint8List>();
  final bool _copy;
  int _offset = 0;
  int _queueCurrentLength = 0;
  int _queueTotalLength = 0;
  bool _dataEmpty = true;
  ByteData __data = ByteData(0);
  ByteData get _data => __data;
  set _data(ByteData data) {
    if (data == null) {
      _dataEmpty = true;
      __data = ByteData(0);
      return;
    }
    __data = data;
    _dataEmpty = false;
  }

  Completer _readAheadCompleter;
  int _readAheadRequired = 0;

  ByteDataReader({this.endian = Endian.big, bool copy = false}) : _copy = copy;

  /// The number of bytes available to read.
  int get remainingLength => _queueCurrentLength - _offset;

  /// The offset in bytes (the current position).
  int get offsetInBytes => _queueTotalLength - remainingLength;

  void _clearQueue() {
    while (_queue.isNotEmpty && _queue.first.length == _offset) {
      final first = _queue.removeFirst();
      _queueCurrentLength -= first.length;
      _offset = 0;
      _data = null;
    }
  }

  void _init(int required) {
    if (remainingLength < required) {
      throw StateError('Not enough bytes to read.');
    }
    _clearQueue();
    if (_offset + required > _queue.first.length) {
      final buffer = BytesBuffer();
      final first = _queue.removeFirst();
      _queueCurrentLength -= first.length;
      buffer.add(first.buffer.asUint8List(
          first.offsetInBytes + _offset, first.lengthInBytes - _offset));
      _offset = 0;
      while (buffer.length < required) {
        final next = _queue.removeFirst();
        _queueCurrentLength -= next.length;
        buffer.add(next);
      }
      final merged = buffer.toBytes();
      _queueCurrentLength += merged.length;
      _queue.addFirst(merged);
      _data = null;
    }
    if (_dataEmpty) {
      _data = ByteData.view(_queue.first.buffer, _queue.first.offsetInBytes);
    }
  }

  void add(List<int> bytes, {bool copy}) {
    _queue.add(castBytes(bytes, copy: copy ?? _copy));
    _queueCurrentLength += bytes.length;
    _queueTotalLength += bytes.length;
    if (_readAheadCompleter != null && remainingLength >= _readAheadRequired) {
      _readAheadCompleter.complete();
      _readAheadCompleter = null;
    }
  }

  /// Completes when minimum [length] amount of bytes are in the buffer.
  Future readAhead(int length) {
    if (remainingLength >= length) {
      return Future.value();
    }
    if (_readAheadCompleter != null && _readAheadRequired == length) {
      return _readAheadCompleter.future;
    }
    if (_readAheadCompleter != null && _readAheadRequired != length) {
      throw StateError('A different readAhead is already waiting.');
    }
    _readAheadRequired = length;
    _readAheadCompleter = Completer();
    return _readAheadCompleter.future;
  }

  Uint8List read(int length, {bool copy}) {
    if (length == 0) {
      return Uint8List(0);
    }
    if (_queue.isEmpty || _queueCurrentLength - _offset < length) {
      throw StateError('Not enough bytes to read.');
    }
    _clearQueue();
    final shouldCopy = copy ?? _copy;
    if (!shouldCopy && (_offset + length <= _queue.first.length)) {
      final value = Uint8List.view(
          _queue.first.buffer, _queue.first.offsetInBytes + _offset, length);
      _offset += length;
      return value;
    }
    final bb = BytesBuffer(copy: copy ?? _copy);
    while (bb.length < length) {
      _clearQueue();
      final remaining = length - bb.length;
      if (_offset + remaining <= _queue.first.length) {
        bb.add(Uint8List.view(_queue.first.buffer,
            _queue.first.offsetInBytes + _offset, remaining));
        _offset += remaining;
      } else {
        final first = _queue.removeFirst();
        _queueCurrentLength -= first.length;
        if (_offset == 0) {
          bb.add(first, copy: false);
        } else {
          bb.add(Uint8List.view(first.buffer, first.offsetInBytes + _offset));
        }
        _data = null;
        _offset = 0;
      }
    }
    return bb.toBytes();
  }

  double readFloat32([Endian endian]) {
    _init(4);
    final value = _data.getFloat32(_offset, endian ?? this.endian);
    _offset += 4;
    return value;
  }

  double readFloat64([Endian endian]) {
    _init(8);
    final value = _data.getFloat64(_offset, endian ?? this.endian);
    _offset += 8;
    return value;
  }

  int readInt8() {
    _init(1);
    final value = _data.getInt8(_offset);
    _offset += 1;
    return value;
  }

  int readInt16([Endian endian]) {
    _init(2);
    final value = _data.getInt16(_offset, endian ?? this.endian);
    _offset += 2;
    return value;
  }

  int readInt32([Endian endian]) {
    _init(4);
    final value = _data.getInt32(_offset, endian ?? this.endian);
    _offset += 4;
    return value;
  }

  int readInt64([Endian endian]) {
    _init(8);
    final value = _data.getInt64(_offset, endian ?? this.endian);
    _offset += 8;
    return value;
  }

  int readInt(int byteLength, [Endian endian]) {
    switch (byteLength) {
      case 1:
        return readInt8();
      case 2:
        return readInt16(endian);
      case 4:
        return readInt32(endian);
      case 8:
        return readInt64(endian);
      default:
        throw ArgumentError(
            'byteLength ($byteLength) must be one of [1, 2, 4, 8].');
    }
  }

  int readUint8() {
    _init(1);
    final value = _data.getUint8(_offset);
    _offset += 1;
    return value;
  }

  int readUint16([Endian endian]) {
    _init(2);
    final value = _data.getUint16(_offset, endian ?? this.endian);
    _offset += 2;
    return value;
  }

  int readUint32([Endian endian]) {
    _init(4);
    final value = _data.getUint32(_offset, endian ?? this.endian);
    _offset += 4;
    return value;
  }

  int readUint64([Endian endian]) {
    _init(8);
    final value = _data.getUint64(_offset, endian ?? this.endian);
    _offset += 8;
    return value;
  }

  int readUint(int byteLength, [Endian endian]) {
    switch (byteLength) {
      case 1:
        return readUint8();
      case 2:
        return readUint16(endian);
      case 4:
        return readUint32(endian);
      case 8:
        return readUint64(endian);
      default:
        throw ArgumentError(
            'byteLength ($byteLength) must be one of [1, 2, 4, 8].');
    }
  }
}