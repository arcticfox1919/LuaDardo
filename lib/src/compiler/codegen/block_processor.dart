import '../ast/block.dart';
import '../ast/exp.dart';
import '../ast/stat.dart';
import 'exp_helper.dart';
import 'exp_processor.dart';
import 'funcinfo.dart';
import 'stat_processor.dart';

class BlockProcessor {

  static void processBlock(FuncInfo fi, Block node) {
    for (Stat stat in node.stats) {
      StatProcessor.processStat(fi, stat);
    }

    if (node.retExps != null) {
      processRetStat(fi, node.retExps, node.lastLine);
    }
  }

  static void processRetStat(FuncInfo fi, List<Exp> exps, int lastLine) {
    int nExps = exps.length;
    if (nExps == 0) {
      fi.emitReturn(lastLine, 0, 0);
      return;
    }

    if (nExps == 1) {
      if (exps[0] is NameExp) {
        NameExp nameExp = exps[0];
        int r = fi.slotOfLocVar(nameExp.name);
        if (r >= 0) {
          fi.emitReturn(lastLine, r, 1);
          return;
        }
      }
      if (exps[0] is FuncCallExp) {
        FuncCallExp fcExp = exps[0];
        int r = fi.allocReg();
        ExpProcessor.processTailCallExp(fi, fcExp, r);
        fi.freeReg();
        fi.emitReturn(lastLine, r, -1);
        return;
      }
    }

    bool multRet = ExpHelper.isVarargOrFuncCall(exps[nExps-1]);
    for (int i = 0; i < nExps; i++) {
      Exp exp = exps[i];
      int r = fi.allocReg();
      if (i == nExps-1 && multRet) {
        ExpProcessor.processExp(fi, exp, r, -1);
      } else {
        ExpProcessor.processExp(fi, exp, r, 1);
      }
    }
    fi.freeRegs(nExps);

    int a = fi.usedRegs; // correct?
    if (multRet) {
      fi.emitReturn(lastLine, a, -1);
    } else {
      fi.emitReturn(lastLine, a, nExps);
    }
  }

}