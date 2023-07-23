import 'lua_state.dart';

/// basic ypes
enum LuaType {
  luaNil,
  luaBoolean,
  luaLightUserdata,
  luaNumber,
  luaString,
  luaTable,
  luaFunction,
  luaUserdata,
  luaThread,
  luaNone,
}


/// arithmetic functions
enum ArithOp {
  luaOpAdd , // +
  luaOpSub , // -
  luaOpMul , // *
  luaOpMod , // %
  luaOpPow , // ^
  luaOpDiv , // /
  luaOpIdiv, // //
  luaOpBand, // &
  luaOpBor , // |
  luaOpBxor, // ~
  luaOpShl , // <<
  luaOpShr , // >>
  luaOpUnm , // -
  luaOpBnot, // ~
}

/// comparison functions
enum CmpOp {
  luaOpEq, // ==
  luaOpLt, // <
  luaOpLe, // <=
}

enum ThreadStatus {
  luaOk,
  luaYield,
  luaErrRun,
  luaErrSyntax,
  luaErrMem,
  luaErrGcmm,
  luaErrErr,
  luaErrFile,
}

typedef DartFunction = int Function(LuaState ls);