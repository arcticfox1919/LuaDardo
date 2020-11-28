import 'block.dart';
import 'exp.dart';
import 'node.dart';

/*
stat ::=  ‘;’ |
	 varlist ‘=’ explist |
	 functioncall |
	 label |
	 break |
	 goto Name |
	 do block end |
	 while exp do block end |
	 repeat block until exp |
	 if exp then block {elseif exp then block} [else block] end |
	 for Name ‘=’ exp ‘,’ exp [‘,’ exp] do block end |
	 for namelist in explist do block end |
	 function funcname funcbody |
	 local function Name funcbody |
	 local namelist [‘=’ explist]
*/
abstract class Stat extends Node {}

class EmptyStat extends Stat {
  static final EmptyStat instance = EmptyStat();
}

class BreakStat extends Stat {
  BreakStat(int line) {
    super.line = line;
  }
}

class LabelStat extends Stat {
  String name;

  LabelStat(this.name);
}

class GotoStat extends Stat {
  String name;

  GotoStat(this.name);
}

class DoStat extends Stat {
  Block block;

  DoStat(this.block);
}

class FuncCallStat extends Stat {
  FuncCallExp exp;

  FuncCallStat(this.exp);
}

class WhileStat extends Stat {
  Exp exp;
  Block block;

  WhileStat(this.exp, this.block);
}

class RepeatStat extends Stat {
  Block block;
  Exp exp;

  RepeatStat(this.block, this.exp);
}

class IfStat extends Stat {
  List<Exp> exps;
  List<Block> blocks;

  IfStat(this.exps, this.blocks);
}

class ForNumStat extends Stat {
  int lineOfFor;
  int lineOfDo;
  String varName;
  Exp InitExp;
  Exp LimitExp;
  Exp StepExp;
  Block block;
}

class ForInStat extends Stat {
  int lineOfDo;
  List<String> nameList;
  List<Exp> expList;
  Block block;
}

class LocalVarDeclStat extends Stat {
  List<String> nameList;
  List<Exp> expList;

  LocalVarDeclStat(int lastLine, List<String> nameList, List<Exp> expList)
      : this.nameList = nameList ?? [],
        this.expList = expList ?? [] {
    super.lastLine = lastLine;
  }
}

class AssignStat extends Stat {
  List<Exp> varList;
  List<Exp> expList;

  AssignStat(int lastLine, this.varList, this.expList) {
    super.lastLine = lastLine;
  }
}

class LocalFuncDefStat extends Stat {
  String name;
  FuncDefExp exp;

  LocalFuncDefStat(this.name,this.exp);
}
