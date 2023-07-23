
import 'package:lua_dardo/src/number/lua_number.dart';

class LuaTableArray {

  List<Object>? _arr;

  bool isArrayIndex(Object key, {bool forInsert = false}) {
    int idx = _floatToIndex(key);
    bool canInsert = forInsert && idx == length;
    return  idx >= 0 && (idx < length || canInsert);
  }

  void operator []= (Object key, Object value) {
    int idx = _floatToIndex(key);
    if (idx < length) {
      _initializedArray[idx] = value;
    } else {
      _initializedArray.add(value);
    }
  }

  Object operator [] (Object key) {
    int idx = _floatToIndex(key);
    return _initializedArray[idx];
  }

  void removeAt(Object key) {
    int idx = _floatToIndex(key);
    _initializedArray.removeAt(idx);
  }

  int _floatToIndex(Object key) {
    int intKey = (key is double && LuaNumber.isInteger(key))
        ? key.toInt()
        : (key is int) ? key : -1;
    return intKey -1;
  }

  int get length => (_arr != null) ? _initializedArray.length : 0;

  List<Object> get _initializedArray {
    if (_arr == null) {
      _arr = [];
    }
    return _arr!;
  }

}
