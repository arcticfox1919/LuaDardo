import 'package:sprintf/sprintf.dart';

import '../api/lua_state.dart';
import '../api/lua_type.dart';

class StringLib {
  static final tagPattern =
      RegExp(r'%[ #+-0]?[0-9]*(\.[0-9]+)?[cdeEfgGioqsuxX%]');

  static const Map<String, DartFunction> _strLib = {
    "len": _strLen,
    "rep": _strRep,
    "reverse": _strReverse,
    "lower": _strLower,
    "upper": _strUpper,
    "sub": _strSub,
    "byte": _strByte,
    "char": _strChar,
    "dump": _strDump,
    "format": _strFormat,
    "packsize": _strPackSize,
    "pack": _strPack,
    "unpack": _strUnpack,
    "find": _strFind,
    "match": _strMatch,
    "gsub": _strGsub,
    "gmatch": _strGmatch,
  };

  static int openStringLib(LuaState ls) {
    ls.newLib(_strLib);
    _createMetatable(ls);
    return 1;
  }

  static void _createMetatable(LuaState ls) {
    ls.createTable(0, 1); /* table to be metatable for strings */
    ls.pushString("dummy"); /* dummy string */
    ls.pushValue(-2); /* copy table */
    ls.setMetatable(-2); /* set table as metatable for strings */
    ls.pop(1); /* pop dummy string */
    ls.pushValue(-2); /* get string library */
    ls.setField(-2, "__index"); /* metatable.__index = string */
    ls.pop(1); /* pop metatable */
  }

  /* Basic String Functions */

// string.len (s)
// http://www.lua.org/manual/5.3/manual.html#pdf-string.len
// lua-5.3.4/src/lstrlib.c#str_len()
  static int _strLen(LuaState ls) {
    String s = ls.checkString(1);
    ls.pushInteger(s.length);
    return 1;
  }

// string.rep (s, n [, sep])
// http://www.lua.org/manual/5.3/manual.html#pdf-string.rep
// lua-5.3.4/src/lstrlib.c#str_rep()
  static int _strRep(LuaState ls) {
    String s = ls.checkString(1);
    int n = ls.checkInteger(2);
    String sep = ls.optString(3, "");

    if (n <= 0) {
      ls.pushString("");
    } else if (n == 1) {
      ls.pushString(s);
    } else {
      var a = [];
      for (var i = 0; i < n; i++) {
        a.add(s);
      }

      ls.pushString(a.join(sep));
    }

    return 1;
  }

// string.reverse (s)
// http://www.lua.org/manual/5.3/manual.html#pdf-string.reverse
// lua-5.3.4/src/lstrlib.c#str_reverse()
  static int _strReverse(LuaState ls) {
    String s = ls.checkString(1);

    var strLen = s.length;
    if (strLen > 1) {
      var a = [];
      for (var i = 0; i < strLen; i++) {
        a[i] = s[strLen - 1 - i];
      }
      ls.pushString(a.join());
    }

    return 1;
  }

// string.lower (s)
// http://www.lua.org/manual/5.3/manual.html#pdf-string.lower
// lua-5.3.4/src/lstrlib.c#str_lower()
  static int _strLower(LuaState ls) {
    String s = ls.checkString(1);
    ls.pushString(s.toLowerCase());
    return 1;
  }

// string.upper (s)
// http://www.lua.org/manual/5.3/manual.html#pdf-string.upper
// lua-5.3.4/src/lstrlib.c#str_upper()
  static int _strUpper(LuaState ls) {
    String s = ls.checkString(1);
    ls.pushString(s.toUpperCase());
    return 1;
  }

// string.sub (s, i [, j])
// http://www.lua.org/manual/5.3/manual.html#pdf-string.sub
// lua-5.3.4/src/lstrlib.c#str_sub()
  static int _strSub(LuaState ls) {
    String s = ls.checkString(1);
    var sLen = s.length;
    var i = posRelat(ls.checkInteger(2), sLen);
    var j = posRelat(ls.optInteger(3, -1), sLen);

    if (i < 1) {
      i = 1;
    }
    if (j > sLen) {
      j = sLen;
    }

    if (i <= j) {
      ls.pushString(s.substring(i - 1, j));
    } else {
      ls.pushString("");
    }

    return 1;
  }

// string.byte (s [, i [, j]])
// http://www.lua.org/manual/5.3/manual.html#pdf-string.byte
// lua-5.3.4/src/lstrlib.c#str_byte()
  static int _strByte(LuaState ls) {
    String s = ls.checkString(1);
    var sLen = s.length;
    var i = posRelat(ls.optInteger(2, 1), sLen);
    var j = posRelat(ls.optInteger(3, i), sLen);

    if (i < 1) {
      i = 1;
    }
    if (j > sLen) {
      j = sLen;
    }

    if (i > j) {
      return 0; /* empty interval; return no values */
    }
//if (j - i >= INT_MAX) { /* arithmetic overflow? */
//  return ls.Error2("string slice too long")
//}

    var n = j - i + 1;
    ls.checkStack2(n, "string slice too long");

    for (var k = 0; k < n; k++) {
      ls.pushInteger(s.codeUnitAt(i + k - 1));
    }
    return n;
  }

// string.char (···)
// http://www.lua.org/manual/5.3/manual.html#pdf-string.char
// lua-5.3.4/src/lstrlib.c#str_char()
  static int _strChar(LuaState ls) {
    var nArgs = ls.getTop();

    // s = make([]byte, nArgs)
    var s = List<int>(nArgs);
    for (var i = 1; i <= nArgs; i++) {
      var c = ls.checkInteger(i);
      ls.argCheck((c & 0xff) == c, i, "value out of range");
      s[i - 1] = c;
    }

    ls.pushString(String.fromCharCodes(s));
    return 1;
  }

// string.dump (function [, strip])
// http://www.lua.org/manual/5.3/manual.html#pdf-string.dump
// lua-5.3.4/src/lstrlib.c#str_dump()
  static int _strDump(LuaState ls) {
    throw Exception("todo: strDump!");
  }

/* PACK/UNPACK */

// string.packsize (fmt)
// http://www.lua.org/manual/5.3/manual.html#pdf-string.packsize
  static int _strPackSize(LuaState ls) {
    var fmt = ls.checkString(1);
    if (fmt == "j") {
      ls.pushInteger(8); // todo
    } else {
      throw Exception("todo: strPackSize!");
    }
    return 1;
  }

// string.pack (fmt, v1, v2, ···)
// http://www.lua.org/manual/5.3/manual.html#pdf-string.pack
  static int _strPack(LuaState ls) {
    throw Exception("todo: strPack!");
  }

// string.unpack (fmt, s [, pos])
// http://www.lua.org/manual/5.3/manual.html#pdf-string.unpack
  static int _strUnpack(LuaState ls) {
    throw Exception("todo: strUnpack!");
  }

/* STRING FORMAT */

// string.format (formatstring, ···)
// http://www.lua.org/manual/5.3/manual.html#pdf-string.format
  static int _strFormat(LuaState ls) {
    var fmtStr = ls.checkString(1);
    if (fmtStr.length <= 1 || fmtStr.indexOf('%') < 0) {
      ls.pushString(fmtStr);
      return 1;
    }

    var argIdx = 1;
    var arr = parseFmtStr(fmtStr);

    for (var i = 0; i < arr.length; i++) {
      if (arr[i][0] == '%') {
        if (arr[i] == "%%") {
          arr[i] = "%";
        } else {
          argIdx += 1;
          arr[i] = _fmtArg(arr[i], ls, argIdx);
        }
      }
    }

    ls.pushString(arr.join());
    return 1;
  }

  static List<String> parseFmtStr(String fmt) {
    if (fmt == "" || fmt.indexOf('%') < 0) {
      return [fmt];
    }

    var parsed = <String>[];
    for (;;) {
      if (fmt == "") {
        break;
      }

      var match = tagPattern.firstMatch(fmt);
      if (match == null) {
        parsed.add(fmt);
        break;
      }

      var head = fmt.substring(0, match.start);
      var tag = fmt.substring(match.start, match.end);
      var tail = fmt.substring(match.end);

      if (head != "") {
        parsed.add(head);
      }
      parsed.add(tag);
      fmt = tail;
    }
    return parsed;
  }

  static String _fmtArg(String tag, LuaState ls, int argIdx) {
    switch (tag[tag.length - 1]) {
      // specifier
      case 'c': // character
        return String.fromCharCode(ls.toInteger(argIdx));
      case 'i':
        tag = tag.substring(0, tag.length - 1) + "d"; // %i -> %d
        return sprintf(tag, [ls.toInteger(argIdx)]);
      case 'd':
      case 'o': // integer, octal
        return sprintf(tag, [ls.toInteger(argIdx)]);
      case 'u': // unsigned integer
        tag = tag.substring(0, tag.length - 1) + "d"; // %u -> %d
        return sprintf(tag, [ls.toInteger(argIdx)]);
      case 'x':
      case 'X': // hex integer
        return sprintf(tag, [ls.toInteger(argIdx)]);
      case 'f': // float
        return sprintf(tag, [ls.toNumber(argIdx)]);
      case 's':
      case 'q': // string
        return sprintf(tag, [ls.toString2(argIdx)]);
      default:
        throw Exception("todo! tag=" + tag);
    }
  }

/* PATTERN MATCHING */

// string.find (s, pattern [, init [, plain]])
// http://www.lua.org/manual/5.3/manual.html#pdf-string.find
  static int _strFind(LuaState ls) {
    var s = ls.checkString(1);
    var sLen = s.length;
    var pattern = ls.checkString(2);
    var init = posRelat(ls.optInteger(3, 1), sLen);
    if (init < 1) {
      init = 1;
    } else if (init > sLen + 1) {
      /* start after string's end? */
      ls.pushNil();
      return 1;
    }
    var plain = ls.toBoolean(4);

    var range = find(s, pattern, init, plain);
    var start = range[0];
    var end = range[1];

    if (start < 0) {
      ls.pushNil();
      return 1;
    }
    ls.pushInteger(start);
    ls.pushInteger(end);
    return 2;
  }

  static List<int> find(String s, String pattern, int init, bool plain) {
    var tail = s;
    if (init > 1) {
      tail = s.substring(init - 1);
    }

    int start;
    if (plain) {
      start = tail.indexOf(pattern);
    } else {
      start = tail.indexOf(RegExp(pattern));
    }
    var end = start + pattern.length - 1;

    if (start >= 0) {
      start += s.length - tail.length + 1;
      end += s.length - tail.length + 1;
    }

    return List<int>(2)
      ..[0] = start
      ..[1] = end;
  }

// string.match (s, pattern [, init])
// http://www.lua.org/manual/5.3/manual.html#pdf-string.match
  static int _strMatch(LuaState ls) {
    var s = ls.checkString(1);
    var sLen = s.length;
    var pattern = ls.checkString(2);
    var init = posRelat(ls.optInteger(3, 1), sLen);
    if (init < 1) {
      init = 1;
    } else if (init > sLen + 1) {
      /* start after string's end? */
      ls.pushNil();
      return 1;
    }

    var captures = match(s, pattern, init);

    if (captures == null || captures.isEmpty) {
      ls.pushNil();
      return 1;
    } else {
      for (var s in captures) {
        ls.pushString(s);
      }
      return captures.length;
    }
  }

  static List<String> match(String s, String pattern, int init) {
    var tail = s;
    if (init > 1) {
      tail = s.substring(init - 1);
    }

    var regExpMatch = RegExp(pattern).firstMatch(tail);
    if (regExpMatch == null) return null;
    return [regExpMatch.group(0)];
  }

// string.gsub (s, pattern, repl [, n])
// http://www.lua.org/manual/5.3/manual.html#pdf-string.gsub
  static int _strGsub(LuaState ls) {
    var s = ls.checkString(1);
    var pattern = ls.checkString(2);
    var repl = ls.checkString(3); // todo
    var n = ls.optInteger(4, -1);

    var r = gsub(s, pattern, repl, n);
    var newStr = r[0];
    var nMatches = r[1];
    ls.pushString(newStr);
    ls.pushInteger(nMatches);
    return 2;
  }

  static List<dynamic> gsub(String s, String pattern, String repl, int n) {
    final regExp = RegExp(pattern);
    RegExpMatch regMatch;

    List<Match> indexes = [];
    for (var i = 0; i < n; i++) {
      regMatch = regExp.firstMatch(s);
      if (regMatch == null) break;
      indexes.add(regMatch);
      s = s.substring(regMatch.end + 1);
    }

    if (indexes.isEmpty) {
      return List(2)
        ..[0] = s
        ..[1] = 0;
    }

    var nMatches = indexes.length;
    var lastEnd = indexes[nMatches - 1].end;
    var head = s.substring(0, lastEnd);
    var tail = s.substring(lastEnd);

    var newHead = head.replaceAll(regExp, repl);
    return List(2)
      ..[0] = '$newHead$tail'
      ..[1] = nMatches;
  }

// string.gmatch (s, pattern)
// http://www.lua.org/manual/5.3/manual.html#pdf-string.gmatch
  static int _strGmatch(LuaState ls) {
    var s = ls.checkString(1);
    var pattern = ls.checkString(2);

    Function gmatchAux = (LuaState ls) {
      var captures = match(s, pattern, 1);
      if (captures != null) {
        String last;
        for (var i = 0; i < captures.length; i++) {
          ls.pushString(captures[i]);
          if (i == captures.length - 1) {
            last = captures[i];
          }
        }
        s = s.substring(s.lastIndexOf(last) + last.length + 1);
        return captures.length;
      } else {
        return 0;
      }
    };

    ls.pushDartFunction(gmatchAux);
    return 1;
  }

/* helper */

/* translate a relative string position: negative means back from end */
  static int posRelat(int pos, int len) {
    if (pos >= 0) {
      return pos;
    } else if (-pos > len) {
      return 0;
    } else {
      return len + pos + 1;
    }
  }
}
