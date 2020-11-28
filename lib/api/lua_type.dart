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
  lua_op_add , // +
  lua_op_sub , // -
  lua_op_mul , // *
  lua_op_mod , // %
  lua_op_pow , // ^
  lua_op_div , // /
  lua_op_idiv, // //
  lua_op_band, // &
  lua_op_bor , // |
  lua_op_bxor, // ~
  lua_op_shl , // <<
  lua_op_shr , // >>
  lua_op_unm , // -
  lua_op_bnot, // ~
}

/// comparison functions
enum CmpOp {
  lua_op_eq, // ==
  lua_op_lt, // <
  lua_op_le, // <=
}

enum ThreadStatus {
  lua_ok,
  lua_yield,
  lua_errrun,
  lua_errsyntax,
  lua_errmem,
  lua_errgcmm,
  lua_errerr,
  lua_errfile,
}

typedef DartFunction = int Function(LuaState ls);