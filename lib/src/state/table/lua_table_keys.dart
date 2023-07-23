
class LuaTableKeys {

  final Map<Object?, Object> _nextKeys = {};

  Object? lastKey;

  int _arrLength = 0;
  Iterable<Object> _keys = [];
  bool _changed = false;

  void update(int arrLength, Iterable<Object> keys) {
    _arrLength = arrLength;
    _keys = keys;
    _changed = true;
  }

  Object? nextKey(Object? key) {
    if (_changed) {
      regenerate();
    }

    Object? nextKey = _nextKeys[key];

    if (nextKey == null && key != null && key != lastKey) {
      throw Exception("invalid key to 'next'");
    }

    return nextKey;
  }

  void regenerate() {
    _nextKeys.clear();

    Object? key = null;

    for (int i=1; i < _arrLength; i++) {
      _nextKeys[key] = i;
      key = i+1;
    }

    for (Object nextKey in _keys) {
      _nextKeys[key] = nextKey;
      key = nextKey;
    }

    lastKey = key;
    _changed = false;
  }

}
