import 'dart:math' as math;
import '../../number/lua_math.dart';
import '../../number/lua_number.dart';
import '../ast/exp.dart';
import '../lexer/token.dart';

class Optimizer {

  static Exp optimizeLogicalOr(BinopExp exp) {
    if (isTrue(exp.exp1)) {
      return exp.exp1; // true or x => true
    }
    if (isFalse(exp.exp1) && !isVarargOrFuncCall(exp.exp2)) {
      return exp.exp2; // false or x => x
    }
    return exp;
  }

  static Exp optimizeLogicalAnd(BinopExp exp) {
    if (isFalse(exp.exp1)) {
      return exp.exp1; // false and x => false
    }
    if (isTrue(exp.exp1) && !isVarargOrFuncCall(exp.exp2)) {
      return exp.exp2; // true and x => x
    }
    return exp;
  }

  static Exp optimizeBitwiseBinaryOp(BinopExp exp) {
    int i = castToInteger(exp.exp1);
    if (i != null) {
      int j = castToInteger(exp.exp2);
      if (j != null) {
        switch (exp.op) {
          case TokenKind.TOKEN_OP_BAND:
            return IntegerExp(exp.line, i & j);
          case TokenKind.TOKEN_OP_BOR:
            return IntegerExp(exp.line, i | j);
          case TokenKind.TOKEN_OP_BXOR:
            return IntegerExp(exp.line, i ^ j);
          case TokenKind.TOKEN_OP_SHL:
            return IntegerExp(exp.line, LuaMath.shiftLeft(i, j));
          case TokenKind.TOKEN_OP_SHR:
            return IntegerExp(exp.line, LuaMath.shiftRight(i, j));
        }
      }
    }
    return exp;
  }

  static Exp optimizeArithBinaryOp(BinopExp exp) {
    if (exp.exp1 is IntegerExp
        && exp.exp2 is IntegerExp
    ) {
      IntegerExp x = exp.exp1;
      IntegerExp y = exp.exp2;
      switch (exp.op) {
        case TokenKind.TOKEN_OP_ADD:
          return IntegerExp(exp.line, x.val + y.val);
        case TokenKind.TOKEN_OP_SUB:
          return IntegerExp(exp.line, x.val - y.val);
        case TokenKind.TOKEN_OP_MUL:
          return IntegerExp(exp.line, x.val * y.val);
        case TokenKind.TOKEN_OP_IDIV:
          if (y.val != 0) {
            return IntegerExp(
                exp.line, (x.val/y.val).floor());
          }
          break;
        case TokenKind.TOKEN_OP_MOD:
          if (y.val != 0) {
            return IntegerExp(
                exp.line, LuaMath.iFloorMod(x.val, y.val));
          }
          break;
      }
    }

    double f = castToFloat(exp.exp1);
    if (f != null) {
      double g = castToFloat(exp.exp2);
      if (g != null) {
        switch (exp.op) {
          case TokenKind.TOKEN_OP_ADD:
            return FloatExp(exp.line, f + g);
          case TokenKind.TOKEN_OP_SUB:
            return FloatExp(exp.line, f - g);
          case TokenKind.TOKEN_OP_MUL:
            return FloatExp(exp.line, f * g);
          case TokenKind.TOKEN_OP_POW:
            return FloatExp(exp.line, math.pow(f, g));
        }
        if (g != 0) {
          switch (exp.op) {
            case TokenKind.TOKEN_OP_DIV:
              return FloatExp(exp.line, f / g);
            case TokenKind.TOKEN_OP_IDIV:
              return FloatExp(exp.line, LuaMath.floorDiv(f, g));
            case TokenKind.TOKEN_OP_MOD:
              return FloatExp(exp.line, LuaMath.floorMod(f, g));
          }
        }
      }
    }

    return
      exp;
  }

  static Exp optimizePow(Exp exp) {
    if (exp is BinopExp) {
      BinopExp binopExp = exp;
      if (binopExp.op == TokenKind.TOKEN_OP_POW) {
        binopExp.exp2 = optimizePow(binopExp.exp2);
      }
      return optimizeArithBinaryOp(binopExp);
    }
    return exp;
  }

  static Exp optimizeUnaryOp(UnopExp exp) {
    switch (exp.op) {
      case TokenKind.TOKEN_OP_UNM:
        return optimizeUnm(exp);
      case TokenKind.TOKEN_OP_NOT:
        return optimizeNot(exp);
      case TokenKind.TOKEN_OP_BNOT:
        return optimizeBnot(exp);
      default:
        return exp;
    }
  }

  static Exp optimizeUnm(UnopExp exp) {
    if (exp.exp is IntegerExp) {
      IntegerExp iExp = exp.exp;
      iExp.val = -iExp.val;
      return iExp;
    }
    if (exp.exp is FloatExp) {
      FloatExp fExp = exp.exp;
      fExp.val = -fExp.val;
      return fExp;
    }
    return exp;
  }

  static Exp optimizeNot(UnopExp exp) {
    Exp subExp = exp.exp;
    if (subExp is NilExp
        || subExp is FalseExp) {
      return TrueExp(exp.line);
    }
    if (subExp is TrueExp
        || subExp is IntegerExp
        || subExp is FloatExp
        || subExp is StringExp) {
      return FalseExp(exp.line);
    }
    return exp;
  }

  static Exp optimizeBnot(UnopExp exp) {
    if (exp.exp is IntegerExp) {
      IntegerExp iExp = exp.exp;
      iExp.val = ~iExp.val;
      return iExp;
    }
    if (exp.exp is FloatExp) {
      FloatExp fExp = exp.exp;
      double f = fExp.val;
      if (LuaNumber.isInteger(f)) {
        return IntegerExp(fExp.line, ~f.toInt());
      }
    }
    return exp;
  }

  static bool isFalse(Exp exp) {
    return exp is FalseExp
        ||
        exp
        is
        NilExp;
  }

  static bool isTrue(Exp exp) {
    return exp is TrueExp
        || exp is IntegerExp
        || exp is FloatExp
        || exp is StringExp;
  }

  static bool isVarargOrFuncCall(Exp exp) {
    return exp is VarargExp
        ||
        exp
        is
        FuncCallExp;
  }

  static int castToInteger(Exp exp) {
    if (exp is IntegerExp) {
      return exp.val;
    }
    if (exp is FloatExp) {
      double f = exp.val;
      return LuaNumber.isInteger(f) ? f.toInt() : null;
  }
    return
    null;
  }

  static double castToFloat(Exp exp) {
    if (exp is IntegerExp) {
      return exp.val.toDouble();
    }
    if (exp is FloatExp) {
      return exp.val;
    }
    return null;
  }

}