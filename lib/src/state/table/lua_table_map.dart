
class LuaTableMap {

  Map<Object, Object>? _map;

  void operator []= (Object key, Object value) {
    _initializedMap[key] = value;
  }

  Object? operator [] (Object key) => _initializedMap[key];

  void remove(Object key) => _initializedMap.remove(key);

  Iterable<Object> get keys => (_map != null)
      ? _initializedMap.keys
      : Iterable.empty();

  Map<Object, Object> get _initializedMap {
    if (_map == null) {
      _map = {};
    }

    return _map!;
  }

}
