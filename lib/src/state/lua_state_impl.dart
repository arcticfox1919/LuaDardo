import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:lua_dardo/src/state/lua_userdata.dart';
import 'package:lua_dardo/src/stdlib/os_lib.dart';

import '../stdlib/math_lib.dart';

import '../stdlib/package_lib.dart';
import '../stdlib/string_lib.dart';
import '../stdlib/table_lib.dart';
import 'package:sprintf/sprintf.dart';

import '../number/lua_number.dart';

import '../stdlib/basic_lib.dart';
import '../api/lua_state.dart';
import '../api/lua_type.dart';
import '../api/lua_vm.dart';
import '../binchunk/binary_chunk.dart';
import '../compiler/compiler.dart';
import '../vm/instruction.dart';
import '../vm/opcodes.dart';
import 'arithmetic.dart';
import 'comparison.dart';
import 'lua_stack.dart';
import 'lua_table.dart';
import 'lua_value.dart';
import 'closure.dart';
import 'upvalue_holder.dart';

class LuaStateImpl implements LuaState, LuaVM {
  LuaStack _stack = LuaStack();

  /// 注册表
  LuaTable registry = LuaTable(0, 0);

  LuaStateImpl() {
    registry.put(lua_ridx_globals, LuaTable(0, 0));
    LuaStack stack = LuaStack();
    stack.state = this;
    _pushLuaStack(stack);
  }

  /// 压入调用栈帧
  void _pushLuaStack(LuaStack newTop) {
    newTop.prev = this._stack;
    this._stack = newTop;
  }

  void _popLuaStack() {
    LuaStack top = this._stack;
    this._stack = top.prev;
    top.prev = null;
  }

  /* metatable */
  LuaTable _getMetatable(Object val) {
    if (val is LuaTable) {
      return val.metatable;
    }
    String key = "_MT${LuaValue.typeOf(val)}";
    Object mt = registry.get(key);
    return mt != null ? (mt as LuaTable) : null;
  }

  void _setMetatable(Object val, LuaTable mt) {
    if (val is LuaTable) {
      val.metatable = mt;
      return;
    }
    String key = "_MT${LuaValue.typeOf(val)}";
    registry.put(key, mt);
  }

  Object _getMetafield(Object val, String fieldName) {
    LuaTable mt = _getMetatable(val);
    return mt != null ? mt.get(fieldName) : null;
  }

  Object getMetamethod(Object a, Object b, String mmName) {
    Object mm = _getMetafield(a, mmName);
    if (mm == null) {
      mm = _getMetafield(b, mmName);
    }
    return mm;
  }

  Object callMetamethod(Object a, Object b, Object mm) {
    _stack.push(mm);
    _stack.push(a);
    _stack.push(b);
    call(2, 1);
    return _stack.pop();
  }

  //**************************************************
  //******************* LuaState *********************
  //**************************************************

  @override
  int absIndex(int idx) {
    return _stack.absIndex(idx);
  }

  @override
  bool checkStack(int n) {
    return true; // TODO
  }

  @override
  void copy(int fromIdx, int toIdx) {
    _stack.set(toIdx, _stack.get(fromIdx));
  }

  @override
  int getTop() {
    return _stack.top();
  }

  @override
  void insert(int idx) {
    rotate(idx, 1);
  }

  @override
  bool isFunction(int idx) {
    return type(idx) == LuaType.luaFunction;
  }

  @override
  bool isInteger(int idx) {
    return _stack.get(idx) is int;
  }

  @override
  bool isNil(int idx) {
    return type(idx) == LuaType.luaNil;
  }

  @override
  bool isNone(int idx) {
    return type(idx) == LuaType.luaNone;
  }

  @override
  bool isNoneOrNil(int idx) {
    LuaType t = type(idx);
    return t == LuaType.luaNone || t == LuaType.luaNil;
  }

  @override
  bool isNumber(int idx) {
    return toNumberX(idx) != null;
  }

  @override
  bool isString(int idx) {
    LuaType t = type(idx);
    return t == LuaType.luaString || t == LuaType.luaNumber;
  }

  @override
  bool isTable(int idx) {
    return type(idx) == LuaType.luaTable;
  }

  @override
  bool isThread(int idx) {
    return type(idx) == LuaType.luaThread;
  }

  @override
  bool isBoolean(int idx) {
    return type(idx) == LuaType.luaBoolean;
  }

  @override
  bool isUserdata(int idx) {
    return type(idx) == LuaType.luaUserdata;
  }

  @override
  void pop(int n) {
    for (int i = 0; i < n; i++) {
      _stack.pop();
    }
  }

  @override
  void pushInteger(int n) {
    _stack.push(n);
  }

  @override
  void pushNil() {
    _stack.push(null);
  }

  @override
  void pushNumber(double n) {
    _stack.push(n);
  }

  @override
  void pushString(String s) {
    _stack.push(s);
  }

  @override
  void pushValue(int idx) {
    _stack.push(_stack.get(idx));
  }

  @override
  void pushBoolean(bool b) {
    _stack.push(b);
  }

  @override
  void remove(int idx) {
    rotate(idx, -1);
    pop(1);
  }

  @override
  void replace(int idx) {
    _stack.set(idx, _stack.pop());
  }

  @override
  void rotate(int idx, int n) {
    int t = _stack.top() - 1; /* end of stack segment being rotated */
    int p = _stack.absIndex(idx) - 1; /* start of segment */
    int m = n >= 0 ? t - n : p - n - 1; /* end of prefix */

    _stack.reverse(p, m); /* reverse the prefix with length 'n' */
    _stack.reverse(m + 1, t); /* reverse the suffix */
    _stack.reverse(p, t); /* reverse the entire segment */
  }

  @override
  void setTop(int idx) {
    int newTop = _stack.absIndex(idx);
    if (newTop < 0) {
      throw Exception("stack underflow!");
    }

    int n = _stack.top() - newTop;
    if (n > 0) {
      for (int i = 0; i < n; i++) {
        _stack.pop();
      }
    } else if (n < 0) {
      for (int i = 0; i > n; i--) {
        _stack.push(null);
      }
    }
  }

  @override
  int toInteger(int idx) {
    int i = toIntegerX(idx);
    return i == null ? 0 : i;
  }

  @override
  int toIntegerX(int idx) {
    Object val = _stack.get(idx);
    return val is int ? val : null;
  }

  @override
  double toNumber(int idx) {
    double n = toNumberX(idx);
    return n == null ? 0 : n;
  }

  @override
  double toNumberX(int idx) {
    Object val = _stack.get(idx);
    if (val is double) {
      return val;
    } else if (val is int) {
      return val.toDouble();
    } else {
      return null;
    }
  }

  @override
  Userdata toUserdata<T>(int idx) {
    Object val = _stack.get(idx);
    return val is Userdata ? val : null;
  }

  @override
  bool toBoolean(int idx) {
    return LuaValue.toBoolean(_stack.get(idx));
  }

  @override
  LuaType type(int idx) {
    return _stack.isValid(idx)
        ? LuaValue.typeOf(_stack.get(idx))
        : LuaType.luaNone;
  }

  @override
  String typeName(LuaType tp) {
    switch (tp) {
      case LuaType.luaNone:
        return "no value";
      case LuaType.luaNil:
        return "nil";
      case LuaType.luaBoolean:
        return "boolean";
      case LuaType.luaNumber:
        return "number";
      case LuaType.luaString:
        return "string";
      case LuaType.luaTable:
        return "table";
      case LuaType.luaFunction:
        return "function";
      case LuaType.luaThread:
        return "thread";
      default:
        return "userdata";
    }
  }

  @override
  String toStr(int idx) {
    Object val = _stack.get(idx);
    if (val is String) {
      return val;
    } else if (val is int || val is double) {
      return val.toString();
    } else {
      return null;
    }
  }

  @override
  void arith(ArithOp op) {
    Object b = _stack.pop();
    Object a = op != ArithOp.lua_op_unm && op != ArithOp.lua_op_bnot
        ? _stack.pop()
        : b;
    Object result = Arithmetic.arith(a, b, op, this);
    if (result != null) {
      _stack.push(result);
    } else {
      throw Exception("arithmetic error!");
    }
  }

  @override
  bool compare(int idx1, int idx2, CmpOp op) {
    if (!_stack.isValid(idx1) || !_stack.isValid(idx2)) {
      return false;
    }

    Object a = _stack.get(idx1);
    Object b = _stack.get(idx2);
    switch (op) {
      case CmpOp.lua_op_eq:
        return Comparison.eq(a, b, this);
      case CmpOp.lua_op_lt:
        return Comparison.lt(a, b, this);
      case CmpOp.lua_op_le:
        return Comparison.le(a, b, this);
      default:
        throw Exception("invalid compare op!");
    }
  }

  @override
  void concat(int n) {
    if (n == 0) {
      _stack.push("");
    } else if (n >= 2) {
      for (int i = 1; i < n; i++) {
        if (isString(-1) && isString(-2)) {
          String s2 = toStr(-1);
          String s1 = toStr(-2);
          pop(2);
          pushString(s1 + s2);
          continue;
        }

        Object b = _stack.pop();
        Object a = _stack.pop();
        Object mm = getMetamethod(a, b, "__concat");
        if (mm != null) {
          _stack.push(callMetamethod(a, b, mm));
          continue;
        }

        throw Exception("concatenation error!");
      }
    }
    // n == 1, do nothing
  }

  @override
  void len(int idx) {
    Object val = _stack.get(idx);
    if (val is String) {
      pushInteger(val.length);
    }

    Object mm = getMetamethod(val, val, "__len");
    if (mm != null) {
      _stack.push(callMetamethod(val, val, mm));
      return;
    }

    if (val is LuaTable) {
      pushInteger(val.length());
    } else {
      throw Exception("length error!");
    }
  }

  @override
  void createTable(int nArr, int nRec) {
    _stack.push(LuaTable(nArr, nRec));
  }

  @override
  LuaType getField(int idx, String k) {
    Object t = _stack.get(idx);
    return _getTable(t, k, false);
  }

  @override
  LuaType getI(int idx, int i) {
    Object t = _stack.get(idx);
    return _getTable(t, i, false);
  }

  @override
  LuaType getTable(int idx) {
    Object t = _stack.get(idx);
    Object k = _stack.pop();
    return _getTable(t, k, false);
  }

  /// [raw] 是否忽略元方法
  /// _setTable 同
  LuaType _getTable(Object t, Object k, bool raw) {
    if (t is LuaTable) {
      LuaTable tbl = t;
      Object v = t.get(k);

      if (raw || v != null || !tbl.hasMetafield("__index")) {
        _stack.push(v);
        return LuaValue.typeOf(v);
      }
    }

    if (!raw) {
      Object mf = _getMetafield(t, "__index");
      if (mf != null) {
        if (mf is LuaTable) {
          return _getTable(mf, k, false);
        } else if (mf is Closure) {
          Object v = callMetamethod(t, k, mf);
          _stack.push(v);
          return LuaValue.typeOf(v);
        }
      }
    }
    throw Exception("${t.runtimeType}, not a table!"); // todo
  }

  @override
  void newTable() {
    createTable(0, 0);
  }

  @override
  Userdata newUserdata<T>() {
    var r = Userdata<T>();
    _stack.push(r);
    return r;
  }

  @override
  void setField(int idx, String k) {
    Object t = _stack.get(idx);
    Object v = _stack.pop();
    _setTable(t, k, v, false);
  }

  @override
  void setTable(int idx) {
    Object t = _stack.get(idx);
    Object v = _stack.pop();
    Object k = _stack.pop();
    _setTable(t, k, v, false);
  }

  @override
  void setI(int idx, int i) {
    Object t = _stack.get(idx);
    Object v = _stack.pop();
    _setTable(t, i, v, false);
  }

  void _setTable(Object t, Object k, Object v, bool raw) {
    if (t is LuaTable) {
      LuaTable tbl = t;
      if (raw || tbl.get(k) != null || !tbl.hasMetafield("__newindex")) {
        tbl.put(k, v);
        return;
      }
    }

    if (!raw) {
      Object mf = _getMetafield(t, "__newindex");
      if (mf != null) {
        if (mf is LuaTable) {
          _setTable(mf, k, v, false);
          return;
        }
        if (mf is Closure) {
          _stack.push(mf);
          _stack.push(t);
          _stack.push(k);
          _stack.push(v);
          call(3, 0);
          return;
        }
      }
    }
    throw Exception("${t.runtimeType}, not a table!");
  }

  @override
  void call(int nArgs, int nResults) {
    Object val = _stack.get(-(nArgs + 1));
    Object f = val is Closure ? val : null;

    if (f == null) {
      Object mf = _getMetafield(val, "__call");
      if (mf != null && mf is Closure) {
        _stack.push(f);
        insert(-(nArgs + 2));
        nArgs += 1;
        f = mf;
      }
    }

    if (f != null) {
      Closure c = f as Closure;
      if (c.proto != null) {
        _callLuaClosure(nArgs, nResults, c);
      } else {
        _callDartClosure(nArgs, nResults, c);
      }
    } else {
      throw Exception("not function!");
    }
  }

  void _callLuaClosure(int nArgs, int nResults, Closure c) {
    int nRegs = c.proto.maxStackSize;
    int nParams = c.proto.numParams;
    bool isVararg = c.proto.isVararg == 1;

    // create new lua stack
    LuaStack newStack = LuaStack(/*nRegs + 20*/);
    newStack.state = this;
    newStack.closure = c;

    // pass args, pop func
    List<Object> funcAndArgs = _stack.popN(nArgs + 1);
    newStack.pushN(funcAndArgs.sublist(1, funcAndArgs.length), nParams);
    if (nArgs > nParams && isVararg) {
      newStack.varargs = funcAndArgs.sublist(nParams + 1, funcAndArgs.length);
    }

    // run closure
    _pushLuaStack(newStack);
    setTop(nRegs);
    _runLuaClosure();
    _popLuaStack();

    // return results
    if (nResults != 0) {
      List<Object> results = newStack.popN(newStack.top() - nRegs);
      //stack.check(results.size())
      _stack.pushN(results, nResults);
    }
  }

  void _callDartClosure(int nArgs, int nResults, Closure c) {
    // create new lua stack
    LuaStack newStack = new LuaStack(/*nRegs+LUA_MINSTACK*/);
    newStack.state = this;
    newStack.closure = c;

    // pass args, pop func
    if (nArgs > 0) {
      newStack.pushN(_stack.popN(nArgs), nArgs);
    }
    _stack.pop();

    // run closure
    _pushLuaStack(newStack);
    int r = c.dartFunc.call(this);
    _popLuaStack();

    // return results
    if (nResults != 0) {
      List<Object> results = newStack.popN(r);
      //stack.check(results.size())
      _stack.pushN(results, nResults);
    }
  }

  void _runLuaClosure() {
    for (;;) {
      int i = fetch();
      OpCode opCode = Instruction.getOpCode(i);
      opCode.action.call(i, this);
      if (opCode.name == "RETURN") {
        break;
      }
    }
  }

  @override
  ThreadStatus load(Uint8List chunk, String chunkName, String mode) {
    Prototype proto = BinaryChunk.isBinaryChunk(chunk)
        ? BinaryChunk.undump(chunk)
        : Compiler.compile(utf8.decode(chunk), chunkName);
    Closure closure = Closure(proto);
    _stack.push(closure);
    if (proto.upvalues.length > 0) {
      Object env = registry.get(lua_ridx_globals);
      closure.upvals[0] = UpvalueHolder.value(env); // todo
    }
    return ThreadStatus.lua_ok;
  }

  @override
  bool isDartFunction(int idx) {
    Object val = _stack.get(idx);
    return val is Closure && val.dartFunc != null;
  }

  @override
  void pushDartFunction(f) {
    _stack.push(Closure.DartFunc(f, 0));
  }

  @override
  toDartFunction(int idx) {
    Object val = _stack.get(idx);
    return val is Closure ? val.dartFunc : null;
  }

  @override
  LuaType getGlobal(String name) {
    Object t = registry.get(lua_ridx_globals);
    return _getTable(t, name, false);
  }

  @override
  void pushGlobalTable() {
    _stack.push(registry.get(lua_ridx_globals));
  }

  @override
  void pushDartClosure(f, int n) {
    Closure closure = Closure.DartFunc(f, n);
    for (int i = n; i > 0; i--) {
      Object val = _stack.pop();
      closure.upvals[i - 1] = UpvalueHolder.value(val); // TODO
    }
    _stack.push(closure);
  }

  @override
  void register(String name, f) {
    pushDartFunction(f);
    setGlobal(name);
  }

  @override
  void setGlobal(String name) {
    Object t = registry.get(lua_ridx_globals);
    Object v = _stack.pop();
    _setTable(t, name, v, false);
  }

  @override
  bool getMetatable(int idx) {
    Object val = _stack.get(idx);
    Object mt = _getMetatable(val);
    if (mt != null) {
      _stack.push(mt);
      return true;
    } else {
      return false;
    }
  }

  @override
  bool rawEqual(int idx1, int idx2) {
    if (!_stack.isValid(idx1) || !_stack.isValid(idx2)) {
      return false;
    }

    Object a = _stack.get(idx1);
    Object b = _stack.get(idx2);
    return Comparison.eq(a, b, null);
  }

  @override
  LuaType rawGet(int idx) {
    Object t = _stack.get(idx);
    Object k = _stack.pop();
    return _getTable(t, k, true);
  }

  @override
  LuaType rawGetI(int idx, int i) {
    Object t = _stack.get(idx);
    return _getTable(t, i, true);
  }

  @override
  int rawLen(int idx) {
    Object val = _stack.get(idx);
    if (val is String) {
      return val.length;
    } else if (val is LuaTable) {
      return val.length();
    } else {
      return 0;
    }
  }

  @override
  void rawSet(int idx) {
    Object t = _stack.get(idx);
    Object v = _stack.pop();
    Object k = _stack.pop();
    _setTable(t, k, v, true);
  }

  @override
  void rawSetI(int idx, int i) {
    Object t = _stack.get(idx);
    Object v = _stack.pop();
    _setTable(t, i, v, true);
  }

  @override
  void setMetatable(int idx) {
    Object val = _stack.get(idx);
    Object mtVal = _stack.pop();

    if (mtVal == null) {
      _setMetatable(val, null);
    } else if (mtVal is LuaTable) {
      _setMetatable(val, mtVal);
    } else {
      throw Exception("table expected!"); // todo
    }
  }

  @override
  bool next(int idx) {
    Object val = _stack.get(idx);
    if (val is LuaTable) {
      LuaTable t = val;
      Object key = _stack.pop();
      Object nextKey = t.nextKey(key);
      if (nextKey != null) {
        _stack.push(nextKey);
        _stack.push(t.get(nextKey));
        return true;
      }
      return false;
    }
    throw Exception("table expected!");
  }

  @override
  int error() {
    Object err = _stack.pop();
    throw Exception(err.toString()); // TODO
  }

  @override
  ThreadStatus pCall(int nArgs, int nResults, int msgh) {
    LuaStack caller = _stack;
    try {
      call(nArgs, nResults);
      return ThreadStatus.lua_ok;
    } catch (e) {
      if (msgh != 0) {
        throw e;
      }
      while (_stack != caller) {
        _popLuaStack();
      }
      _stack.push("$e"); // TODO
      return ThreadStatus.lua_errrun;
    }
  }

  //**************************************************
  //******************* LuaAuxLib ********************
  //**************************************************
  @override
  void argCheck(bool cond, int arg, String extraMsg) {
    if (!cond) {
      argError(arg, extraMsg);
    }
  }

  @override
  int argError(int arg, String extraMsg) {
    return error2("bad argument #%d (%s)", [arg, extraMsg]); // todo
  }

  @override
  bool callMeta(int obj, String e) {
    obj = absIndex(obj);
    if (getMetafield(obj, e) == LuaType.luaNil) {
      /* no metafield? */
      return false;
    }

    pushValue(obj);
    call(1, 1);
    return true;
  }

  @override
  void checkAny(int arg) {
    if (type(arg) == LuaType.luaNone) {
      argError(arg, "value expected");
    }
  }

  @override
  int checkInteger(int arg) {
    int i = toIntegerX(arg);
    if (i == null) {
      intError(arg);
    }
    return i;
  }

  void intError(int arg) {
    if (isNumber(arg)) {
      argError(arg, "number has no integer representation");
    } else {
      tagError(arg, LuaType.luaNumber);
    }
  }

  void tagError(int arg, LuaType tag) {
    typeError(arg, typeName(tag));
  }

  void typeError(int arg, String tname) {
    String typeArg; /* name for the type of the actual argument */
    if (getMetafield(arg, "__name") == LuaType.luaString) {
      typeArg = toStr(-1); /* use the given type name */
    } else if (type(arg) == LuaType.luaLightUserdata) {
      typeArg = "light userdata"; /* special name for messages */
    } else {
      typeArg = typeName2(arg); /* standard name */
    }
    String msg = tname + " expected, got " + typeArg;
    pushString(msg);
    argError(arg, msg);
  }

  @override
  double checkNumber(int arg) {
    double f = toNumberX(arg);
    if (f == null) {
      tagError(arg, LuaType.luaNumber);
    }
    return f;
  }

  @override
  void checkStack2(int sz, String msg) {
    if (!checkStack(sz)) {
      if (msg != "") {
        error2("stack overflow (%s)", [msg]);
      } else {
        error2("stack overflow");
      }
    }
  }

  @override
  String checkString(int arg) {
    String s = toStr(arg);
    if (s == null) {
      tagError(arg, LuaType.luaString);
    }
    return s;
  }

  @override
  void checkType(int arg, LuaType t) {
    if (type(arg) != t) {
      tagError(arg, t);
    }
  }

  @override
  bool doFile(String filename) {
    return loadFile(filename) == ThreadStatus.lua_ok &&
        pCall(0, lua_multret, 0) == ThreadStatus.lua_ok;
  }

  @override
  bool doString(String str) {
    return loadString(str) == ThreadStatus.lua_ok &&
        pCall(0, lua_multret, 0) == ThreadStatus.lua_ok;
  }

  @override
  int error2(String fmt, [List<Object> a]) {
    pushFString(fmt, a);
    return error();
  }

  @override
  LuaType getMetafield(int obj, String e) {
    if (!getMetatable(obj)) {
      /* no metatable? */
      return LuaType.luaNil;
    }

    pushString(e);
    LuaType tt = rawGet(-2);
    if (tt == LuaType.luaNil) {
      /* is metafield nil? */
      pop(2); /* remove metatable and metafield */
    } else {
      remove(-2); /* remove only metatable */
    }
    return tt; /* return metafield type */
  }

  @override
  LuaType getMetatableAux(String tname) {
    return getField(lua_registryindex, tname);
  }

  @override
  bool getSubTable(int idx, String fname) {
    if (getField(idx, fname) == LuaType.luaTable) {
      return true; /* table already there */
    }
    pop(1); /* remove previous result */
    idx = _stack.absIndex(idx);
    newTable();
    pushValue(-1); /* copy to be left at top */
    setField(idx, fname); /* assign new table to field */
    return false; /* false, because did not find table there */
  }

  @override
  int len2(int idx) {
    len(idx);
    int i = toIntegerX(-1);
    if (i == null) {
      error2("object length is not an integer");
    }
    pop(1);
    return i;
  }

  @override
  ThreadStatus loadFile(String filename) {
    return loadFileX(filename, "bt");
  }

  @override
  ThreadStatus loadFileX(String filename, String mode) {
    try {
      File file = File(filename);
      return load(file.readAsBytesSync(), "@" + filename, mode);
    } catch (e, s) {
      print(e);
      print(s);
      return ThreadStatus.lua_errfile;
    }
  }

  @override
  ThreadStatus loadString(String s) {
    return load(utf8.encode(s), s, "bt");
  }

  @override
  void newLib(Map l) {
    newLibTable(l);
    setFuncs(l, 0);
  }

  @override
  void newLibTable(Map l) {
    createTable(0, l.length);
  }

  @override
  void openLibs() {
    Map<String, DartFunction> libs = <String, DartFunction>{
      "_G": BasicLib.openBaseLib,
      "package": PackageLib.openPackageLib,
      "table": TableLib.openTableLib,
      "string": StringLib.openStringLib,
      "math": MathLib.openMathLib,
      "os": OSLib.openOSLib
    };

    libs.forEach((name, fun) {
      requireF(name, fun, true);
      pop(1);
    });
  }

  @override
  int optInteger(int arg, int dft) {
    return isNoneOrNil(arg) ? dft : checkInteger(arg);
  }

  @override
  double optNumber(int arg, double d) {
    return isNoneOrNil(arg) ? d : checkNumber(arg);
  }

  @override
  String optString(int arg, String d) {
    return isNoneOrNil(arg) ? d : checkString(arg);
  }

  @override
  void pushFString(String fmt, [List<Object> a]) {
    var str = a == null ? fmt : sprintf(fmt, a);
    pushString(str);
  }

  @override
  void requireF(String modname, openf, bool glb) {
    getSubTable(lua_registryindex, "_LOADED");
    getField(-1, modname); /* LOADED[modname] */
    if (!toBoolean(-1)) {
      /* package not already loaded? */
      pop(1); /* remove field */
      pushDartFunction(openf);
      pushString(modname); /* argument to open function */
      call(1, 1); /* call 'openf' to open module */
      pushValue(-1); /* make copy of module (call result) */
      setField(-3, modname); /* _LOADED[modname] = module */
    }
    remove(-2); /* remove _LOADED table */
    if (glb) {
      pushValue(-1); /* copy of module */
      setGlobal(modname); /* _G[modname] = module */
    }
  }

  @override
  void setMetatableAux(String tname) {
    getMetatableAux(tname);
    setMetatable(-2);
  }

  @override
  void setFuncs(Map<String, DartFunction> l, int nup) {
    checkStack2(nup, "too many upvalues");
    l.forEach((name, fun) {
      /* fill the table with given functions */
      for (int i = 0; i < nup; i++) {
        /* copy upvalues to the top */
        pushValue(-nup);
      }
      // r[-(nup+2)][name]=fun
      pushDartClosure(fun, nup); /* closure with those upvalues */
      setField(-(nup + 2), name);
    });
    pop(nup); /* remove upvalues */
  }

  @override
  bool stringToNumber(String s) {
    int i = LuaNumber.parseInteger(s);
    if (i != null) {
      pushInteger(i);
      return true;
    }
    double f = LuaNumber.parseFloat(s);
    if (f != null) {
      pushNumber(f);
      return true;
    }
    return false;
  }

  @override
  Object toPointer(int idx) {
    return _stack.get(idx); // todo
  }

  @override
  String toString2(int idx) {
    if (callMeta(idx, "__tostring")) {
      /* metafield? */
      if (!isString(-1)) {
        error2("'__tostring' must return a string");
      }
    } else {
      switch (type(idx)) {
        case LuaType.luaNumber:
          if (isInteger(idx)) {
            pushString("${toInteger(idx)}"); // todo
          } else {
            pushString(sprintf("%g", [toNumber(idx)]));
          }
          break;
        case LuaType.luaString:
          pushValue(idx);
          break;
        case LuaType.luaBoolean:
          pushString(toBoolean(idx) ? "true" : "false");
          break;
        case LuaType.luaNil:
          pushString("nil");
          break;
        default:
          LuaType tt = getMetafield(idx, "__name");
          /* try name */
          String kind =
              tt == LuaType.luaString ? checkString(-1) : typeName2(idx);
          pushString("$kind: ${toPointer(idx).hashCode}");
          if (tt != LuaType.luaNil) {
            remove(-2); /* remove '__name' */
          }
          break;
      }
    }
    return checkString(-1);
  }

  @override
  String typeName2(int idx) {
    return typeName(type(idx));
  }

  @override
  bool newMetatable(String tname) {
    if (getMetatableAux(tname) != LuaType.luaNil) {
      /* name already in use? */
      return false; /* leave previous value on top, but return false */
    }

    pop(1);
    createTable(0, 2); /* create metatable */
    pushString(tname);
    setField(-2, "__name"); /* metatable.__name = tname */
    pushValue(-1);
    setField(lua_registryindex, tname); /* registry.name = metatable */
    return true;
  }

  int ref(int t) {
    int _ref;
    if (isNil(-1)) {
      pop(1); /* remove from stack */
      return -1; /* 'nil' has a unique fixed reference */
    }
    t = absIndex(t);
    rawGetI(t, 0); /* get first free element */
    _ref = toInteger(-1); /* ref = t[freelist] */
    pop(1); /* remove it from stack */
    if (_ref != 0) {
      /* any free element? */
      rawGetI(t, _ref); /* remove it from list */
      rawSetI(t, 0); /* (t[freelist] = t[ref]) */
    } else
      /* no free elements */
      _ref = rawLen(t) + 1;
    /* get a new reference */

    rawSetI(t, _ref);
    return _ref;
  }

  void unRef(int t, int ref) {
    if (ref >= 0) {
      t = absIndex(t);
      rawGetI(t, 0);
      rawSetI(t, ref); /* t[ref] = t[freelist] */
      pushInteger(ref);
      rawSetI(t, 0); /* t[freelist] = ref */
    }
  }

  //**************************************************
  //******************** LuaVM ***********************
  //**************************************************
  @override
  void addPC(int n) {
    _stack.pc += n;
  }

  @override
  int fetch() {
    return _stack.closure.proto.code[_stack.pc++];
  }

  @override
  void getConst(int idx) {
    _stack.push(_stack.closure.proto.constants[idx]);
  }

  @override
  int getPC() {
    return _stack.pc;
  }

  @override
  void getRK(int rk) {
    if (rk > 0xFF) {
      // constant
      getConst(rk & 0xFF);
    } else {
      // register
      pushValue(rk + 1);
    }
  }

  @override
  void loadProto(int idx) {
    Prototype proto = _stack.closure.proto.protos[idx];
    Closure closure = Closure(proto);
    _stack.push(closure);

    for (int i = 0; i < proto.upvalues.length; i++) {
      Upvalue uvInfo = proto.upvalues[i];
      int uvIdx = uvInfo.idx;
      if (uvInfo.instack == 1) {
        if (_stack.openuvs == null) {
          _stack.openuvs = Map<int, UpvalueHolder>();
        }
        if (_stack.openuvs.containsKey(uvIdx)) {
          closure.upvals[i] = _stack.openuvs[uvIdx];
        } else {
          closure.upvals[i] = UpvalueHolder(_stack, uvIdx);
          _stack.openuvs[uvIdx] = closure.upvals[i];
        }
      } else {
        closure.upvals[i] = _stack.closure.upvals[uvIdx];
      }
    }
  }

  @override
  void loadVararg(int n) {
    List<Object> varargs =
        _stack.varargs != null ? _stack.varargs : const <Object>[];
    if (n < 0) {
      n = varargs.length;
    }

    //stack.check(n)
    _stack.pushN(varargs, n);
  }

  @override
  int registerCount() {
    return _stack.closure.proto.maxStackSize;
  }

  @override
  void closeUpvalues(int a) {
    if (_stack.openuvs != null) {
      _stack.openuvs.removeWhere((k, v) {
        if (v.index >= a - 1) {
          v.migrate();
          return true;
        } else
          return false;
      });
    }
  }

//**************************************************
//**************************************************
//**************************************************
}
