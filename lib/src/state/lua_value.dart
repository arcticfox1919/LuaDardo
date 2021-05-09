import 'package:lua_dardo/src/state/lua_userdata.dart';

import '../api/lua_type.dart';
import '../number/lua_number.dart';
import 'closure.dart';
import 'lua_table.dart';

class LuaValue {

  static LuaType typeOf(Object val) {
    if (val == null) {
      return LuaType.luaNil;
    } else if (val is bool) {
      return LuaType.luaBoolean;
    } else if (val is int || val is double) {
      return LuaType.luaNumber;
    } else if (val is String) {
      return LuaType.luaString;
    } else if (val is LuaTable) {
      return LuaType.luaTable;
    } else if (val is Closure) {
      return LuaType.luaFunction;
    } else if (val is Userdata){
      return LuaType.luaUserdata;
    } else {
      throw Exception("TODO");
    }
  }

  static bool toBoolean(Object val) {
    if (val == null) {
      return false;
    } else if (val is bool) {
      return val;
    } else {
      return true;
    }
  }

  // http://www.lua.org/manual/5.3/manual.html#3.4.3
  static double toFloat(Object val) {
    if (val is double) {
      return val.toDouble();
    } else if (val is int) {
      return val.toDouble();
    } else if (val is String) {
      return LuaNumber.parseFloat(val);
    } else {
      return null;
    }
  }

  // http://www.lua.org/manual/5.3/manual.html#3.4.3
  static int otoInteger(Object val) {
    if (val is int) {
      return val;
    } else if (val is double) {
      double n = val;
      return LuaNumber.isInteger(n) ? n.toInt() : null;
    } else if (val is String) {
      return stoInteger(val);
    } else {
      return null;
    }
  }

  static int stoInteger(String s) {
    int i = LuaNumber.parseInteger(s);
    if (i != null) {
      return i;
    }
    double f = LuaNumber.parseFloat(s);
    if (f != null && LuaNumber.isInteger(f)) {
      return f.toInt();
    }
    return null;
  }

}