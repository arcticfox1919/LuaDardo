import '../ast/exp.dart';

class ExpHelper {

  static bool isVarargOrFuncCall(Exp exp) {
    return exp is VarargExp
    || exp is FuncCallExp;
  }

  static List<Exp> removeTailNils(List<Exp> exps) {
    while (!exps.isEmpty) {
      if (exps[exps.length - 1] is NilExp) {
        exps.removeAt(exps.length - 1);
      } else {
        break;
      }
    }
    return exps;
  }

  static int lineOf(Exp exp) {
    if (exp is TableAccessExp) {
      return lineOf(exp.prefixExp);
    }
    if (exp is ConcatExp) {
      return lineOf(exp.exps[0]);
    }
    if (exp is BinopExp) {
      return lineOf(exp.exp1);
    }
    return exp.line;
  }

  static int lastLineOf(Exp exp) {
    if (exp is TableAccessExp) {
      return lastLineOf(exp.prefixExp);
    }
    if (exp is ConcatExp) {
      return lastLineOf(exp.exps[0]);
    }
    if (exp is BinopExp) {
      return lastLineOf(exp.exp1);
    }
    if (exp is UnopExp) {
      return lastLineOf(exp.exp);
    }
    int lastLine = exp.lastLine;
    if (lastLine > 0) {
      return lastLine;
    }
    return exp.line;
  }

}