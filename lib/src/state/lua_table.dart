import 'dart:collection';

import '../number/lua_number.dart';

class LuaTable {
  /// 元表
  LuaTable metatable;
  List<Object> arr;
  Map<Object, Object> map;

  // used by next()
  Map<Object, Object> keys;
  Object lastKey;
  bool changed;

  LuaTable(int nArr, int nRec) {
    if (nArr > 0) {
      // arr = List<Object>(nArr);
      arr = List<Object>();
    }
    if (nRec > 0) {
      // map =  Map<Object, Object>(nRec);
      map =  HashMap<Object, Object>();
    }
  }

  bool hasMetafield(String fieldName) {
    return metatable != null && metatable.get(fieldName) != null;
  }

  int length() {
    return arr == null ? 0 : arr.length;
  }

  Object get(Object key) {
    key = floatToInteger(key);

    if (arr != null && key is int) {
      int idx = key;
      if (idx >= 1 && idx <= arr.length) {
        return arr[idx - 1];
      }
    }

    return map != null ? map[key] : null;
  }

  void put(Object key, Object val) {
    if (key == null) {
      throw Exception("table index is nil!");
    }
    if (key is double && key.isNaN) {
      throw Exception("table index is NaN!");
    }

    key = floatToInteger(key);
    if (key is int) {
      int idx = key;
      if (idx >= 1) {
        if (arr == null) {
          arr = List<Object>();
        }

        int arrLen = arr.length;
        if (idx <= arrLen) {
          arr[idx-1] = val;
          if (idx == arrLen && val == null) {
            shrinkArray();
          }
          return;
        }
        if (idx == arrLen + 1) {
          if (map != null) {
            map.remove(key);
          }
          if (val != null) {
            arr.add(val);
            expandArray();
          }
          return;
        }
      }
    }

    if (val != null) {
      if (map == null) {
        map = HashMap<Object, Object>();
      }
      map[key] = val;
    } else {
      if (map != null) {
        map.remove(key);
      }
    }
  }

  Object floatToInteger(Object key) {
    if (key is double) {
      double f = key;
      if (LuaNumber.isInteger(f)) {
        return f.toInt();
      }
    }
    return key;
  }

  void shrinkArray() {
    for (int i = arr.length - 1; i >= 0; i--) {
      if (arr[i] == null) {
        arr.removeAt(i);
      }
    }
  }

  void expandArray() {
    if (map != null) {
      for (int idx = arr.length + 1; ; idx++) {
        Object val = map.remove(idx);
        if (val != null) {
          arr.add(val);
        } else {
          break;
        }
      }
    }
  }

  Object nextKey(Object key) {
    if (keys == null || (key == null && changed)) {
      initKeys();
      changed = false;
    }

    Object nextKey = keys[key];
    if (nextKey == null && key != null && key != lastKey) {
      throw Exception("invalid key to 'next'");
    }

    return nextKey;
  }

  void initKeys() {
    if (keys == null) {
      keys = HashMap<Object, Object>();
    } else {
      keys.clear();
    }
    Object key = null;
    if (arr != null) {
      for (int i = 0; i < arr.length; i++) {
        if (arr[i] != null) {
          int nextKey = i + 1;
          keys[key] = nextKey;
          key = nextKey;
        }
      }
    }
    if (map != null) {
      for (Object k in map.keys) {
        Object v = map[k];
        if (v != null) {
          keys[key] = k;
          key = k;
        }
      }
    }
    lastKey = key;
  }
}