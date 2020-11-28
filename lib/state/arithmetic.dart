import 'dart:math' as math;
import '../api/lua_type.dart';
import '../number/lua_math.dart';
import 'lua_state_impl.dart';
import 'lua_value.dart';


class Arithmetic{
  static final _integerOps =  <Function>[
        (a, b) => a + b,     // lua_op_add
        (a, b) => a - b,     // lua_op_sub
        (a, b) => a * b,     // lua_op_mul
        LuaMath.iFloorMod,   // lua_op_mod
        null,                // lua_op_pow
        null,                // lua_op_div
        LuaMath.iFloorDiv,   // lua_op_idiv
        (a, b) => a & b,     // lua_op_band
        (a, b) => a | b,     // lua_op_bor
        (a, b) => a ^ b,     // lua_op_bxor
        LuaMath.shiftLeft,   // lua_op_shl
        LuaMath.shiftRight,  // lua_op_shr
        (a, b) => -a,        // lua_op_unm
        (a, b) => ~a,        // lua_op_bnot
  ];


  static final _floatOps =  <Function>[
        (a, b) => a + b,     // lua_op_add
        (a, b) => a - b,     // lua_op_sub
        (a, b) => a * b,     // lua_op_mul
        LuaMath.floorMod,    // lua_op_mod
        math.pow,            // lua_op_pow
        (a, b) => a / b,     // lua_op_div
        LuaMath.floorDiv,    // lua_op_idiv
        null,                // lua_op_band
        null,                // lua_op_bor
        null,                // lua_op_bxor
        null,                // lua_op_shl
        null,                // lua_op_shr
        (a, b) => -a,        // lua_op_unm
        null,                // lua_op_bnot
  ];

  static final _metamethods = [
    "__add",
    "__sub",
    "__mul",
    "__mod",
    "__pow",
    "__div",
    "__idiv",
    "__band",
    "__bor",
    "__bxor",
    "__shl",
    "__shr",
    "__unm",
    "__bnot"
  ];

  static Object arith(Object a, Object b, ArithOp op, LuaStateImpl ls) {
    Function integerFunc = _integerOps[op.index];
    Function floatFunc = _floatOps[op.index];

    if (floatFunc == null) { // bitwise
      int x = LuaValue.otoInteger(a);
      if (x != null) {
        int y = LuaValue.otoInteger(b);
        if (y != null) {
          return integerFunc.call(x, y);
        }
      }
    } else { // arith
      if (integerFunc != null) { // add,sub,mul,mod,idiv,unm
        if (a is int && b is int) {
          return integerFunc.call(a, b);
        }
      }
      double x = LuaValue.toFloat(a);
      if (x != null) {
        double y = LuaValue.toFloat(b);
        if (y != null) {
          return floatFunc.call(x, y);
        }
      }
    }
    Object mm = ls.getMetamethod(a, b, _metamethods[op.index]);
    if (mm != null) {
      return ls.callMetamethod(a, b, mm);
    }

    throw Exception("arithmetic error!");
  }

}