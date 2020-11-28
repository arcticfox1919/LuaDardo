import 'lua_state_impl.dart';
import 'lua_table.dart';
import 'lua_value.dart';

class Comparison {

  static bool eq(Object a, Object b, LuaStateImpl ls) {
    if (a == null) {
      return b == null;
    } else if (a is bool || a is String) {
      return a == b;
    } else if (a is int) {
      return a == b ||
          (b is double && b == a.toDouble());
    } else if (a is double) {
      return a == b ||
          (b is int && a == b.toDouble());
    } else if (a is LuaTable) { // meta method
      if (b is LuaTable && a != b && ls != null) {
        Object mm = ls.getMetamethod(a, b, "__eq");
        if (mm != null) {
          return LuaValue.toBoolean(ls.callMetamethod(a, b, mm));
        }
      }
      return a == b;
    }else {
      return a == b;
    }
  }

  static bool lt(Object a, Object b, LuaStateImpl ls) {
    if (a is String && b is String) {
      return a.compareTo(b) < 0;
    }
    if (a is int) {
      if (b is int) {
        return a < b;
      } else if (b is double) {
        return a.compareTo(b) < 0;
      }
    }
    if (a is double) {
      if (b is double) {
        return a < b;
      } else if (b is int) {
        return a.compareTo(b) < 0;
      }
    }

    Object mm = ls.getMetamethod(a, b, "__lt");
    if (mm != null) {
      return LuaValue.toBoolean(ls.callMetamethod(a, b, mm));
    }

    throw Exception("comparison error!");
  }

  static bool le(Object a, Object b, LuaStateImpl ls) {
    if (a is String && b is String) {
      return a.compareTo(b) <= 0;
    }
    if (a is int) {
      if (b is int) {
        return a <= b;
      } else if (b is double) {
        return a.compareTo(b) <= 0;;
      }
    }
    if (a is double) {
      if (b is double) {
        return  a <= b;
      } else if (b is int) {
        return a.compareTo(b) <= 0;
      }
    }

    Object mm = ls.getMetamethod(a, b, "__le");
    if (mm != null) {
      return LuaValue.toBoolean(ls.callMetamethod(a, b, mm));
    }
    mm = ls.getMetamethod(b, a, "__lt");
    if (mm != null) {
      return LuaValue.toBoolean(ls.callMetamethod(b, a, mm));
    }

    throw Exception("comparison error!");
  }

}