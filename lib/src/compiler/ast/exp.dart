

import '../lexer/token.dart';
import 'block.dart';
import 'node.dart';

abstract class Exp extends Node {

}

/*
prefixexp ::= Name |
              ‘(’ exp ‘)’ |
              prefixexp ‘[’ exp ‘]’ |
              prefixexp ‘.’ Name |
              prefixexp ‘:’ Name args |
              prefixexp args
*/
abstract class PrefixExp extends Exp {

}

class NilExp extends Exp {
  NilExp(int line) {
    super.line = line;
  }
}

class TrueExp extends Exp {
  TrueExp(int line) {
    super.line = line;
  }
}

class FalseExp extends Exp {
  FalseExp(int line) {
    super.line = line;
  }
}

class VarargExp extends Exp {
  VarargExp(int line) {
    super.line = line;
  }
}

class IntegerExp extends Exp {
  int val;

  IntegerExp(int line, int val) {
    this.val = val;
    super.line = line;
  }
}

class FloatExp extends Exp {
  double val;

  FloatExp(int line, this.val) {
    super.line = line;
  }

}

class StringExp extends Exp {
  String str;

  StringExp.fromToken(Token token) {
    super.line = token.line;
    this.str = token.value;
  }

  StringExp(int line, this.str) {
    super.line = line;
  }
}

class NameExp extends PrefixExp {
  String name;

  NameExp(int line, this.name) {
    super.line = line;
  }
}

class UnopExp extends Exp {
  TokenKind op; // operator
  Exp exp;

  UnopExp(Token op, this.exp) {
    super.line = op.line;
    this.exp = exp;

    if (op.kind == TokenKind.TOKEN_OP_MINUS) {
      this.op = TokenKind.TOKEN_OP_UNM;
    } else if (op.kind == TokenKind.TOKEN_OP_WAVE) {
      this.op = TokenKind.TOKEN_OP_BNOT;
    } else {
      this.op = op.kind;
    }
  }
}

class BinopExp extends Exp {
  TokenKind op; // operator
  Exp exp1;
  Exp exp2;

  BinopExp(Token op,this.exp1,this.exp2){
    line = op.line;
    if (op.kind == TokenKind.TOKEN_OP_MINUS) {
      this.op = TokenKind.TOKEN_OP_SUB;
    } else if (op.kind == TokenKind.TOKEN_OP_WAVE) {
      this.op = TokenKind.TOKEN_OP_BXOR;
    } else {
      this.op = op.kind;
    }
  }

}

class ConcatExp extends Exp {
  List<Exp> exps;

  ConcatExp(int line, this.exps);
}

class TableConstructorExp extends Exp {
  List<Exp> keyExps = <Exp>[];
  List<Exp> valExps = <Exp>[];
}

class FuncDefExp extends Exp {
  List<String> parList;
  bool IsVararg;
  Block block;
}

class ParensExp extends PrefixExp {
  Exp exp;

  ParensExp(this.exp);
}

class TableAccessExp extends PrefixExp {
  Exp prefixExp;
  Exp keyExp;

  TableAccessExp(int lastLine, this.prefixExp, this.keyExp) {
    super.lastLine = lastLine;
  }
}

class FuncCallExp extends PrefixExp {
  Exp prefixExp;
  StringExp nameExp;
  List<Exp> args;
}
