import 'dart:convert';
import 'dart:io';

import '../api/lua_state.dart';
import '../api/lua_type.dart';

class BasicLib {
  static const Map<String, DartFunction> _baseFuncs = {
    "print": _basePrint,
    "assert": _baseAssert,
    "error": _baseError,
    "select": _baseSelect,
    "ipairs": _baseIPairs,
    "pairs": _basePairs,
    "next": _baseNext,
    "load": _baseLoad,
    "loadfile": _baseLoadFile,
    "dofile": _baseDoFile,
    "pcall": _basePCall,
    "xpcall": _baseXPCall,
    "getmetatable": _baseGetMetatable,
    "setmetatable": _baseSetMetatable,
    "rawequal": _baseRawEqual,
    "rawlen": _baseRawLen,
    "rawget": _baseRawGet,
    "rawset": _baseRawSet,
    "type": _baseType,
    "tostring": _baseToString,
    "tonumber": _baseToNumber,
    /* placeholders */
    "_G": null,
    "_VERSION": null
  };

  static int openBaseLib(LuaState ls) {
    /* open lib into global table */
    ls.pushGlobalTable();
    ls.setFuncs(_baseFuncs, 0);
    /* set global _G */
    ls.pushValue(-1);
    ls.setField(-2, "_G");
    /* set global _VERSION */
    ls.pushString("Lua 5.3"); // todo
    ls.setField(-2, "_VERSION");
    return 1;
  }

// print (···)
// http://www.lua.org/manual/5.3/manual.html#pdf-print
// lua-5.3.4/src/lbaselib.c#luaB_print()
  static int _basePrint(LuaState ls) {
    int n = ls.getTop(); /* number of arguments */
    ls.getGlobal("tostring");
    for (int i = 1; i <= n; i++) {
      ls.pushValue(-1); /* function to be called */
      ls.pushValue(i); /* value to print */
      ls.call(1, 1);
      String s = ls.toStr(-1); /* get result */
      if (s == null) {
        return ls.error2("'tostring' must return a string to 'print'");
      }
      if (i > 1) {
        stdout.write("\t");
      }
      stdout.write(s);
      ls.pop(1); /* pop result */
    }
    stdout.write('\n');
    return 0;
  }

// assert (v [, message])
// http://www.lua.org/manual/5.3/manual.html#pdf-assert
// lua-5.3.4/src/lbaselib.c#luaB_assert()
  static int _baseAssert(LuaState ls) {
    if (ls.toBoolean(1)) {
      /* condition is true? */
      return ls.getTop(); /* return all arguments */
    } else {
      /* error */
      ls.checkAny(1); /* there must be a condition */
      ls.remove(1); /* remove it */
      ls.pushString("assertion failed!"); /* default message */
      ls.setTop(1); /* leave only message (default if no other one) */
      return _baseError(ls); /* call 'error' */
    }
  }

// error (message [, level])
// http://www.lua.org/manual/5.3/manual.html#pdf-error
// lua-5.3.4/src/lbaselib.c#luaB_error()
  static int _baseError(LuaState ls) {
    int level = ls.optInteger(2, 1);
    ls.setTop(1);
    if (ls.type(1) == LuaType.luaString && level > 0) {
      // ls.where(level) /* add extra information */
      // ls.pushValue(1)
      // ls.concat(2)
    }
    return ls.error();
  }

// select (index, ···)
// http://www.lua.org/manual/5.3/manual.html#pdf-select
// lua-5.3.4/src/lbaselib.c#luaB_select()
  static int _baseSelect(LuaState ls) {
    int n = ls.getTop();
    if (ls.type(1) == LuaType.luaString && ls.checkString(1) == "#") {
      ls.pushInteger(n - 1);
      return 1;
    } else {
      int i = ls.checkInteger(1);
      if (i < 0) {
        i = n + i;
      } else if (i > n) {
        i = n;
      }
      ls.argCheck(1 <= i, 1, "index out of range");
      return n - i;
    }
  }

// ipairs (t)
// http://www.lua.org/manual/5.3/manual.html#pdf-ipairs
// lua-5.3.4/src/lbaselib.c#luaB_ipairs()
  static int _baseIPairs(LuaState ls) {
    ls.checkAny(1);
    ls.pushDartFunction(iPairsAux); /* iteration function */
    ls.pushValue(1); /* state */
    ls.pushInteger(0); /* initial value */
    return 3;
  }

  static int iPairsAux(LuaState ls) {
    int i = ls.checkInteger(2) + 1;
    ls.pushInteger(i);
    return ls.getI(1, i) == LuaType.luaNil ? 1 : 2;
  }

// pairs (t)
// http://www.lua.org/manual/5.3/manual.html#pdf-pairs
// lua-5.3.4/src/lbaselib.c#luaB_pairs()
  static int _basePairs(LuaState ls) {
    ls.checkAny(1);
    if (ls.getMetafield(1, "__pairs") == LuaType.luaNil) {
      /* no metamethod? */
      ls.pushDartFunction(_baseNext); /* will return generator, */
      ls.pushValue(1); /* state, */
      ls.pushNil();
    } else {
      ls.pushValue(1); /* argument 'self' to metamethod */
      ls.call(1, 3); /* get 3 values from metamethod */
    }
    return 3;
  }

// next (table [, index])
// http://www.lua.org/manual/5.3/manual.html#pdf-next
// lua-5.3.4/src/lbaselib.c#luaB_next()
  static int _baseNext(LuaState ls) {
    ls.checkType(1, LuaType.luaTable);
    ls.setTop(2); /* create a 2nd argument if there isn't one */
    if (ls.next(1)) {
      return 2;
    } else {
      ls.pushNil();
      return 1;
    }
  }

// load (chunk [, chunkname [, mode [, env]]])
// http://www.lua.org/manual/5.3/manual.html#pdf-load
// lua-5.3.4/src/lbaselib.c#luaB_load()
  static int _baseLoad(LuaState ls) {
    String chunk = ls.toStr(1);
    String mode = ls.optString(3, "bt");
    int env = !ls.isNone(4) ? 4 : 0; /* 'env' index or 0 if no 'env' */
    if (chunk != null) {
      /* loading a string? */
      String chunkName = ls.optString(2, chunk);
      ThreadStatus status = ls.load(utf8.encode(chunk), chunkName, mode);
      return loadAux(ls, status, env);
    } else {
      /* loading from a reader function */
      throw Exception("loading from a reader function"); // todo
    }
  }

// lua-5.3.4/src/lbaselib.c#load_aux()
  static int loadAux(LuaState ls, ThreadStatus status, int envIdx) {
    if (status == ThreadStatus.lua_ok) {
      if (envIdx != 0) {
        /* 'env' parameter? */
        throw Exception("todo!");
      }
      return 1;
    } else {
      /* error (message is on top of the stack) */
      ls.pushNil();
      ls.insert(-2); /* put before error message */
      return 2; /* return nil plus error message */
    }
  }

// loadfile ([filename [, mode [, env]]])
// http://www.lua.org/manual/5.3/manual.html#pdf-loadfile
// lua-5.3.4/src/lbaselib.c#luaB_loadfile()
  static int _baseLoadFile(LuaState ls) {
    String fname = ls.optString(1, "");
    String mode = ls.optString(1, "bt");
    int env = !ls.isNone(3) ? 3 : 0; /* 'env' index or 0 if no 'env' */
    ThreadStatus status = ls.loadFileX(fname, mode);
    return loadAux(ls, status, env);
  }

// dofile ([filename])
// http://www.lua.org/manual/5.3/manual.html#pdf-dofile
// lua-5.3.4/src/lbaselib.c#luaB_dofile()
  static int _baseDoFile(LuaState ls) {
    String fname = ls.optString(1, "bt");
    ls.setTop(1);
    if (ls.loadFile(fname) != ThreadStatus.lua_ok) {
      return ls.error();
    }
    ls.call(0, lua_multret);
    return ls.getTop() - 1;
  }

// pcall (f [, arg1, ···])
// http://www.lua.org/manual/5.3/manual.html#pdf-pcall
  static int _basePCall(LuaState ls) {
    int nArgs = ls.getTop() - 1;
    ThreadStatus status = ls.pCall(nArgs, -1, 0);
    ls.pushBoolean(status == ThreadStatus.lua_ok);
    ls.insert(1);
    return ls.getTop();
  }

// xpcall (f, msgh [, arg1, ···])
// http://www.lua.org/manual/5.3/manual.html#pdf-xpcall
  static int _baseXPCall(LuaState ls) {
    throw Exception("todo!");
  }

// getmetatable (object)
// http://www.lua.org/manual/5.3/manual.html#pdf-getmetatable
// lua-5.3.4/src/lbaselib.c#luaB_getmetatable()
  static int _baseGetMetatable(LuaState ls) {
    ls.checkAny(1);
    if (!ls.getMetatable(1)) {
      ls.pushNil();
      return 1; /* no metatable */
    }
    ls.getMetafield(1, "__metatable");
    return 1; /* returns either __metatable field (if present) or metatable */
  }

// setmetatable (table, metatable)
// http://www.lua.org/manual/5.3/manual.html#pdf-setmetatable
// lua-5.3.4/src/lbaselib.c#luaB_setmetatable()
  static int _baseSetMetatable(LuaState ls) {
    LuaType t = ls.type(2);
    ls.checkType(1, LuaType.luaTable);
    ls.argCheck(t == LuaType.luaNil || t == LuaType.luaTable, 2,
        "nil or table expected");
    if (ls.getMetafield(1, "__metatable") != LuaType.luaNil) {
      return ls.error2("cannot change a protected metatable");
    }
    ls.setTop(2);
    ls.setMetatable(1);
    return 1;
  }

// rawequal (v1, v2)
// http://www.lua.org/manual/5.3/manual.html#pdf-rawequal
// lua-5.3.4/src/lbaselib.c#luaB_rawequal()
  static int _baseRawEqual(LuaState ls) {
    ls.checkAny(1);
    ls.checkAny(2);
    ls.pushBoolean(ls.rawEqual(1, 2));
    return 1;
  }

// rawlen (v)
// http://www.lua.org/manual/5.3/manual.html#pdf-rawlen
// lua-5.3.4/src/lbaselib.c#luaB_rawlen()
  static int _baseRawLen(LuaState ls) {
    LuaType t = ls.type(1);
    ls.argCheck(t == LuaType.luaTable || t == LuaType.luaString, 1,
        "table or string expected");
    ls.pushInteger(ls.rawLen(1));
    return 1;
  }

// rawget (table, index)
// http://www.lua.org/manual/5.3/manual.html#pdf-rawget
// lua-5.3.4/src/lbaselib.c#luaB_rawget()
  static int _baseRawGet(LuaState ls) {
    ls.checkType(1, LuaType.luaTable);
    ls.checkAny(2);
    ls.setTop(2);
    ls.rawGet(1);
    return 1;
  }

// rawset (table, index, value)
// http://www.lua.org/manual/5.3/manual.html#pdf-rawset
// lua-5.3.4/src/lbaselib.c#luaB_rawset()
  static int _baseRawSet(LuaState ls) {
    ls.checkType(1, LuaType.luaTable);
    ls.checkAny(2);
    ls.checkAny(3);
    ls.setTop(3);
    ls.rawSet(1);
    return 1;
  }

// type (v)
// http://www.lua.org/manual/5.3/manual.html#pdf-type
// lua-5.3.4/src/lbaselib.c#luaB_type()
  static int _baseType(LuaState ls) {
    LuaType t = ls.type(1);
    ls.argCheck(t != LuaType.luaNone, 1, "value expected");
    ls.pushString(ls.typeName(t));
    return 1;
  }

// tostring (v)
// http://www.lua.org/manual/5.3/manual.html#pdf-tostring
// lua-5.3.4/src/lbaselib.c#luaB_tostring()
  static int _baseToString(LuaState ls) {
    ls.checkAny(1);
    ls.toString2(1);
    return 1;
  }

// tonumber (e [, base])
// http://www.lua.org/manual/5.3/manual.html#pdf-tonumber
// lua-5.3.4/src/lbaselib.c#luaB_tonumber()
  static int _baseToNumber(LuaState ls) {
    if (ls.isNoneOrNil(2)) {
      /* standard conversion? */
      ls.checkAny(1);
      if (ls.type(1) == LuaType.luaNumber) {
        /* already a number? */
        ls.setTop(1); /* yes; return it */
        return 1;
      } else {
        String s = ls.toStr(1);
        if (s != null) {
          if (ls.stringToNumber(s)) {
            return 1; /* successful conversion to number */
          } /* else not a number */
        }
      }
    } else {
      ls.checkType(1, LuaType.luaString); /* no numbers as strings */
      String s = ls.toStr(1).trim();
      int base = ls.checkInteger(2);
      ls.argCheck(2 <= base && base <= 36, 2, "base out of range");
      try {
        int n = int.parse(s, radix: base);
        ls.pushInteger(n);
        return 1;
      } catch (e) {
        /* else not a number */
      }
    }
    /* else not a number */
    ls.pushNil(); /* not a number */
    return 1;
  }
}
