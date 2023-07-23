import 'package:lua_dardo/src/state/table/lua_table_array.dart';
import 'package:lua_dardo/src/state/table/lua_table_keys.dart';
import 'package:lua_dardo/src/state/table/lua_table_map.dart';

class LuaTable {
  /// 元表
  LuaTable? metatable;

  final LuaTableArray arr = LuaTableArray();
  final LuaTableMap map = LuaTableMap();
  final LuaTableKeys keys = LuaTableKeys();

  bool hasMetafield(String fieldName) => metatable?.get(fieldName) != null;

  void put(Object? key, Object? val) {
    if (key == null) {
      throw Exception("table index is nil!");
    }

    if (key is double && key.isNaN) {
      throw Exception("table index is NaN!");
    }

    if (val == null) {
      _remove(key);
    } else if (arr.isArrayIndex(key)) {
      arr[key] = val;
    } else if (arr.isArrayIndex(key, forInsert: true)) {
      arr[key] = val;
      _expandArray();
    } else {
      map[key] = val;
    }

    keys.update(arr.length, map.keys);
  }

  void _remove(Object key) {
    if (arr.isArrayIndex(key)) {
      arr.removeAt(key);
    } else {
      map.remove(key);
    }
  }

  void _expandArray() {
    int key = arr.length + 1;
    Object? value = map[key];
    while (value != null) {
      arr[key] = value;
      map.remove(key);

      key++;
      value = map[key];
    }
  }

  Object? get(Object? key) {
    if (key != null) {
      return (arr.isArrayIndex(key)) ? arr[key] : map[key];
    }
    return null;
  }

  Object? nextKey(Object? key) => keys.nextKey(key);

  int length() => arr.length;

}
