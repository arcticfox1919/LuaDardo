import 'dart:io';

import '../vm/Instructions.dart';

import '../api/lua_state.dart';
import '../api/lua_type.dart';

// key, in the registry, for table of loaded modules
const lua_loaded_table = "_LOADED";

// key, in the registry, for table of preloaded loaders
const lua_preload_table = "_PRELOAD";


const lua_path_sep = ";";
const lua_path_mark = "?";
const lua_exec_dir = "!";
const lua_igmark = "-";

class PackageLib {
  static final lua_dirsep = Platform.pathSeparator;

  static const Map<String, DartFunction> _pkgFuncs = {
    "searchpath": _pkgSearchPath,
    /* placeholders */
    "preload": null,
    "cpath": null,
    "path": null,
    "searchers": null,
    "loaded": null,
  };

  static const Map<String, DartFunction> _llFuncs = {"require": _pkgRequire};

  static int openPackageLib(LuaState ls) {
    ls.newLib(_pkgFuncs);
    _createSearchersTable(ls);
    // set paths
    ls.pushString("./?.lua;./?/init.lua");
    ls.setField(-2, "path");
    // store config information
    ls.pushString(
        '$lua_dirsep\n$lua_path_sep\n$lua_path_mark\n$lua_exec_dir\n$lua_igmark\n');
    ls.setField(-2, "config");
    // set field 'loaded'
    ls.getSubTable(lua_registryindex, lua_loaded_table);
    ls.setField(-2, "loaded");
    // set field 'preload'
    ls.getSubTable(lua_registryindex, lua_preload_table);
    ls.setField(-2, "preload");
    ls.pushGlobalTable();
    ls.pushValue(-2); // set 'package' as upvalue for next lib
    ls.setFuncs(_llFuncs, 1); // open lib into global table
    ls.pop(1); // pop global table
    return 1; // return 'package' table
  }

  static void _createSearchersTable(LuaState ls) {
    List<DartFunction> searchers = [_preloadSearcher, _luaSearcher];
    var len = searchers.length;
    ls.createTable(len, 0);
    for (var idx = 0; idx < len; idx++) {
      ls.pushValue(-2);
      ls.pushDartClosure(searchers[idx], 1);
      ls.rawSetI(-2, idx + 1);
    }
    ls.setField(-2, "searchers");
  }

  static int _preloadSearcher(LuaState ls) {
    var name = ls.checkString(1);
    ls.getField(lua_registryindex, "_PRELOAD");

    if (ls.getField(-1, name) == LuaType.luaNil) {
      /* not found? */
      ls.pushString("\n\tno field package.preload['" + name + "']");
    }
    return 1;
  }

  static int _luaSearcher(LuaState ls) {
    var name = ls.checkString(1);
    ls.getField(Instructions.luaUpvalueIndex(1), "path");
    var path = ls.toStr(-1);
    if (path == null) {
      return ls.error2("'package.path' must be a string");
    }

    try {
      var filename = _searchPath(name, path, ".", lua_dirsep);
      if (ls.loadFile(filename) == ThreadStatus.lua_ok) {
        /* module loaded successfully? */
        ls.pushString(filename); /* will be 2nd argument to module */
        return 2; /* return open function and file name */
      } else {
        return ls.error2("error loading module '%s' from file '%s':\n\t%s",
            [ls.checkString(1), filename, ls.checkString(-1)]);
      }
    } catch (e) {
      ls.pushString(e.toString());
      return 1;
    }
  }

  static String _searchPath(
      String name, String path, String sep, String dirSep) {
    if (sep != "") {
      name = name.replaceAll(sep, dirSep);
    }

    for (var filename in path.split(lua_path_sep)) {
      filename = filename.replaceAll(lua_path_mark, name);
      if (FileSystemEntity.isDirectorySync(filename)) {
        if (Directory(filename).existsSync()) {
          return filename;
        } else {
          throw Exception("\n\tno file '" + filename + "'");
        }
      } else {
        if (File(filename).existsSync()) {
          return filename;
        } else {
          throw Exception("\n\tno file '" + filename + "'");
        }
      }
    }
  }

  // package.searchpath (name, path [, sep [, rep]])
  // http://www.lua.org/manual/5.3/manual.html#pdf-package.searchpath
  // loadlib.c#ll_searchpath
  static int _pkgSearchPath(LuaState ls) {
    var name = ls.checkString(1);
    var path = ls.checkString(2);
    var sep = ls.optString(3, ".");
    var rep = ls.optString(4, lua_dirsep);

    try {
      var filename = _searchPath(name, path, sep, rep);
      ls.pushString(filename);
      return 1;
    } catch (e) {
      ls.pushNil();
      ls.pushString(e.toString());
      return 2;
    }
  }

  // require (modname)
  // http://www.lua.org/manual/5.3/manual.html#pdf-require
  static int _pkgRequire(LuaState ls) {
    var name = ls.checkString(1);
    ls.setTop(1); // LOADED table will be at index 2
    ls.getField(lua_registryindex, lua_loaded_table);
    ls.getField(2, name); // LOADED[name]
    if (ls.toBoolean(-1)) {
      // is it there?
      return 1; // package is already loaded
    }
    // else must load package
    ls.pop(1); // remove 'getfield' result
    _findLoader(ls, name);
    ls.pushString(name); // pass name as argument to module loader
    ls.insert(-2); // name is 1st argument (before search data)
    ls.call(2, 1); // run loader to load module

    if (!ls.isNil(-1)) {
      // non-nil return?
      ls.setField(2, name); // LOADED[name] = returned value
    }

    // module set no value?
    if (ls.getField(2, name) == LuaType.luaNil) {
      ls.pushBoolean(true); // use true as result
      ls.pushValue(-1); // extra copy to be returned
      ls.setField(2, name); // LOADED[name] = true
    }
    return 1;
  }

  static void _findLoader(LuaState ls, String name) {
    // push 'package.searchers' to index 3 in the stack
    if (ls.getField(Instructions.luaUpvalueIndex(1), "searchers") !=
        LuaType.luaTable) {
      ls.error2("'package.searchers' must be a table");
      return;
    }

    // to build error message
    var errMsg = "module '$name' not found:";

    //  iterate over available searchers to find a loader
    for (var i = 1;; i++) {
      if (ls.rawGetI(3, i) == LuaType.luaNil) {
        // no more searchers?
        ls.pop(1); // remove nil
        ls.error2(errMsg); // create error message
      }

      ls.pushString(name);
      ls.call(1, 2); // call it

      if (ls.isFunction(-2)) {
        // did it find a loader?
        return; // module loader found
      } else if (ls.isString(-2)) {
        // searcher returned error message?
        ls.pop(1); // remove extra return
        errMsg += ls.checkString(-1); // concatenate error message
      } else {
        ls.pop(2); // remove both returns
      }
    }
  }
}
