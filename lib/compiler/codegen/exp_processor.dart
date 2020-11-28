import '../../vm/opcodes.dart';
import '../ast/exp.dart';
import 'block_processor.dart';
import 'exp_helper.dart';
import 'funcinfo.dart';
import '../lexer/token.dart';

class ArgAndKind {
  int arg;
  int kind;
}

class ExpProcessor {
  // kind of operands
  static final int ARG_CONST = 1; // const index
  static final int ARG_REG = 2; // register index
  static final int ARG_UPVAL = 4; // upvalue index
  static final int ARG_RK = ARG_REG | ARG_CONST;
  static final int ARG_RU = ARG_REG | ARG_UPVAL;

  //static final int ARG_RUK   = ARG_REG | ARG_UPVAL | ARG_CONST;

  static void processExp(FuncInfo fi, Exp node, int a, int n) {
    if (node is NilExp) {
      fi.emitLoadNil(node.line, a, n);
    } else if (node is FalseExp) {
      fi.emitLoadBool(node.line, a, 0, 0);
    } else if (node is TrueExp) {
      fi.emitLoadBool(node.line, a, 1, 0);
    } else if (node is IntegerExp) {
      fi.emitLoadK(node.line, a, node.val);
    } else if (node is FloatExp) {
      fi.emitLoadK(node.line, a, node.val);
    } else if (node is StringExp) {
      fi.emitLoadK(node.line, a, node.str);
    } else if (node is ParensExp) {
      processExp(fi, node.exp, a, 1);
    } else if (node is VarargExp) {
      processVarargExp(fi, node, a, n);
    } else if (node is FuncDefExp) {
      processFuncDefExp(fi, node, a);
    } else if (node is TableConstructorExp) {
      processTableConstructorExp(fi, node, a);
    } else if (node is UnopExp) {
      processUnopExp(fi, node, a);
    } else if (node is BinopExp) {
      processBinopExp(fi, node, a);
    } else if (node is ConcatExp) {
      processConcatExp(fi, node, a);
    } else if (node is NameExp) {
      processNameExp(fi, node, a);
    } else if (node is TableAccessExp) {
      processTableAccessExp(fi, node, a);
    } else if (node is FuncCallExp) {
      processFuncCallExp(fi, node, a, n);
    }
  }

  static void processVarargExp(FuncInfo fi, VarargExp node, int a, int n) {
    if (!fi.isVararg) {
      throw Exception("cannot use '...' outside a vararg function");
    }
    fi.emitVararg(node.line, a, n);
  }

  // f[a] = function(args) body end
  static void processFuncDefExp(FuncInfo fi, FuncDefExp node, int a) {
    FuncInfo subFI = FuncInfo(fi, node);
    fi.subFuncs.add(subFI);

    if (node.parList != null) {
      for (String param in node.parList) {
        subFI.addLocVar(param, 0);
      }
    }

    BlockProcessor.processBlock(subFI, node.block);
    subFI.exitScope(subFI.pc() + 2);
    subFI.emitReturn(node.lastLine, 0, 0);

    int bx = fi.subFuncs.length - 1;
    fi.emitClosure(node.lastLine, a, bx);
  }

  static void processTableConstructorExp(
      FuncInfo fi, TableConstructorExp node, int a) {
    int nArr = 0;
    for (Exp keyExp in node.keyExps) {
      if (keyExp == null) {
        nArr++;
      }
    }
    int nExps = node.keyExps.length;
    bool multRet =
        nExps > 0 && ExpHelper.isVarargOrFuncCall(node.valExps[nExps - 1]);

    fi.emitNewTable(node.line, a, nArr, nExps - nArr);

    int arrIdx = 0;
    for (int i = 0; i < node.keyExps.length; i++) {
      Exp keyExp = node.keyExps[i];
      Exp valExp = node.valExps[i];

      if (keyExp == null) {
        arrIdx++;
        int tmp = fi.allocReg();
        if (i == nExps - 1 && multRet) {
          processExp(fi, valExp, tmp, -1);
        } else {
          processExp(fi, valExp, tmp, 1);
        }

        if (arrIdx % 50 == 0 || arrIdx == nArr) {
          // LFIELDS_PER_FLUSH
          int n = arrIdx % 50;
          if (n == 0) {
            n = 50;
          }
          fi.freeRegs(n);
          int line = ExpHelper.lastLineOf(valExp);
          int c = (arrIdx - 1) ~/ 50 + 1; // todo: c > 0xFF
          if (i == nExps - 1 && multRet) {
            fi.emitSetList(line, a, 0, c);
          } else {
            fi.emitSetList(line, a, n, c);
          }
        }

        continue;
      }

      int b = fi.allocReg();
      processExp(fi, keyExp, b, 1);
      int c = fi.allocReg();
      processExp(fi, valExp, c, 1);
      fi.freeRegs(2);

      int line = ExpHelper.lastLineOf(valExp);
      fi.emitSetTable(line, a, b, c);
    }
  }

  // r[a] = op exp
  static void processUnopExp(FuncInfo fi, UnopExp node, int a) {
    int oldRegs = fi.usedRegs;
    int b = expToOpArg(fi, node.exp, ARG_REG).arg;
    fi.emitUnaryOp(node.line, node.op, a, b);
    fi.usedRegs = oldRegs;
  }

  // r[a] = exp1 op exp2
  static void processBinopExp(FuncInfo fi, BinopExp node, int a) {
    if (node.op == TokenKind.TOKEN_OP_AND || node.op == TokenKind.TOKEN_OP_OR) {
      int oldRegs = fi.usedRegs;

      int b = expToOpArg(fi, node.exp1, ARG_REG).arg;
      fi.usedRegs = oldRegs;
      if (node.op == TokenKind.TOKEN_OP_AND) {
        fi.emitTestSet(node.line, a, b, 0);
      } else {
        fi.emitTestSet(node.line, a, b, 1);
      }
      int pcOfJmp = fi.emitJmp(node.line, 0, 0);

      b = expToOpArg(fi, node.exp2, ARG_REG).arg;
      fi.usedRegs = oldRegs;
      fi.emitMove(node.line, a, b);
      fi.fixSbx(pcOfJmp, fi.pc() - pcOfJmp);
    } else {
      int oldRegs = fi.usedRegs;
      int b = expToOpArg(fi, node.exp1, ARG_RK).arg;
      int c = expToOpArg(fi, node.exp2, ARG_RK).arg;
      fi.emitBinaryOp(node.line, node.op, a, b, c);
      fi.usedRegs = oldRegs;
    }
  }

  // r[a] = exp1 .. exp2
  static void processConcatExp(FuncInfo fi, ConcatExp node, int a) {
    for (Exp subExp in node.exps) {
      int a1 = fi.allocReg();
      processExp(fi, subExp, a1, 1);
    }

    int c = fi.usedRegs - 1;
    int b = c - node.exps.length + 1;
    fi.freeRegs(c - b + 1);
    fi.emitABC(node.line, OpCodeKind.CONCAT, a, b, c);
  }

  // r[a] = name
  static void processNameExp(FuncInfo fi, NameExp node, int a) {
    int r = fi.slotOfLocVar(node.name);
    if (r >= 0) {
      fi.emitMove(node.line, a, r);
      return;
    }

    int idx = fi.indexOfUpval(node.name);
    if (idx >= 0) {
      fi.emitGetUpval(node.line, a, idx);
      return;
    }

    // x => _ENV['x']
    Exp prefixExp = NameExp(node.line, "_ENV");
    Exp keyExp = StringExp(node.line, node.name);
    TableAccessExp taExp = TableAccessExp(node.line, prefixExp, keyExp);
    processTableAccessExp(fi, taExp, a);
  }

  // r[a] = prefix[key]
  static void processTableAccessExp(FuncInfo fi, TableAccessExp node, int a) {
    int oldRegs = fi.usedRegs;
    ArgAndKind argAndKindB = expToOpArg(fi, node.prefixExp, ARG_RU);
    int b = argAndKindB.arg;
    int c = expToOpArg(fi, node.keyExp, ARG_RK).arg;
    fi.usedRegs = oldRegs;

    if (argAndKindB.kind == ARG_UPVAL) {
      fi.emitGetTabUp(node.lastLine, a, b, c);
    } else {
      fi.emitGetTable(node.lastLine, a, b, c);
    }
  }

  // r[a] = f(args)
  static void processFuncCallExp(FuncInfo fi, FuncCallExp node, int a, int n) {
    int nArgs = prepFuncCall(fi, node, a);
    fi.emitCall(node.line, a, nArgs, n);
  }

  // return f(args)
  static void processTailCallExp(FuncInfo fi, FuncCallExp node, int a) {
    int nArgs = prepFuncCall(fi, node, a);
    fi.emitTailCall(node.line, a, nArgs);
  }

  static int prepFuncCall(FuncInfo fi, FuncCallExp node, int a) {
    List<Exp> args = node.args;
    if (args == null) {
      args = <Exp>[];
    }
    int nArgs = args.length;
    bool lastArgIsVarargOrFuncCall = false;

    processExp(fi, node.prefixExp, a, 1);
    if (node.nameExp != null) {
      fi.allocReg();
      ArgAndKind argAndKindC = expToOpArg(fi, node.nameExp, ARG_RK);
      fi.emitSelf(node.line, a, a, argAndKindC.arg);
      if (argAndKindC.kind == ARG_REG) {
        fi.freeRegs(1);
      }
    }
    for (int i = 0; i < args.length; i++) {
      Exp arg = args[i];
      int tmp = fi.allocReg();
      if (i == nArgs - 1 && ExpHelper.isVarargOrFuncCall(arg)) {
        lastArgIsVarargOrFuncCall = true;
        processExp(fi, arg, tmp, -1);
      } else {
        processExp(fi, arg, tmp, 1);
      }
    }
    fi.freeRegs(nArgs);

    if (node.nameExp != null) {
      fi.freeReg();
      nArgs++;
    }
    if (lastArgIsVarargOrFuncCall) {
      nArgs = -1;
    }

    return nArgs;
  }

  static ArgAndKind expToOpArg(FuncInfo fi, Exp node, int argKinds) {
    ArgAndKind ak = ArgAndKind();

    if ((argKinds & ARG_CONST) > 0) {
      int idx = -1;
      if (node is NilExp) {
        idx = fi.indexOfConstant(null);
      } else if (node is FalseExp) {
        idx = fi.indexOfConstant(false);
      } else if (node is TrueExp) {
        idx = fi.indexOfConstant(true);
      } else if (node is IntegerExp) {
        idx = fi.indexOfConstant(node.val);
      } else if (node is FloatExp) {
        idx = fi.indexOfConstant(node.val);
      } else if (node is StringExp) {
        idx = fi.indexOfConstant(node.str);
      }
      if (idx >= 0 && idx <= 0xFF) {
        ak.arg = 0x100 + idx;
        ak.kind = ARG_CONST;
        return ak;
      }
    }

    if (node is NameExp) {
      if ((argKinds & ARG_REG) > 0) {
        int r = fi.slotOfLocVar(node.name);
        if (r >= 0) {
          ak.arg = r;
          ak.kind = ARG_REG;
          return ak;
        }
      }
      if ((argKinds & ARG_UPVAL) > 0) {
        int idx = fi.indexOfUpval(node.name);
        if (idx >= 0) {
          ak.arg = idx;
          ak.kind = ARG_UPVAL;
          return ak;
        }
      }
    }

    int a = fi.allocReg();
    processExp(fi, node, a, 1);
    ak.arg = a;
    ak.kind = ARG_REG;
    return ak;
  }
}
