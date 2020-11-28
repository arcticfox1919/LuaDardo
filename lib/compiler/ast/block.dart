import 'exp.dart';
import 'node.dart';
import 'stat.dart';

// chunk ::= block
// type Chunk *Block

// block ::= {stat} [retstat]
// retstat ::= return [explist] [‘;’]
// explist ::= exp {‘,’ exp}
class Block extends Node {
  List<Stat> stats;
  List<Exp> retExps;


  @override
  String toString() {
    var sb = StringBuffer();
    sb.writeln('{');
    if(stats != null && stats.isNotEmpty){
      sb.write('Stats:[');
      for(var stat in stats){
        _statToStr(stat,sb);
      }
      sb.write(']');
    }
    if(retExps != null && retExps.isNotEmpty){
      sb.write(',\nRetExps:[');
      for(var exp in retExps){
        _expToStr(exp,sb);
      }
      sb.writeln(']');
    }
    sb.writeln('}');
    return sb.toString();
  }
  
  _statToStr(Stat stat,StringBuffer sb){
    if(stat is EmptyStat){
      sb.writeln('{ kind:EmptyStat, line:${stat.line},lastLine:${stat.lastLine} },');
    }else if(stat is BreakStat){
      sb.writeln('{ kind:BreakStat, line:${stat.line},lastLine:${stat.lastLine} },');
    }else if(stat is LabelStat){
      sb.writeln('{ kind:LabelStat, line:${stat.line},lastLine:${stat.lastLine},name:${stat.name} },');
    }else if(stat is GotoStat){
      sb.writeln('{ kind:GotoStat, line:${stat.line},lastLine:${stat.lastLine},name:${stat.name} },');
    }else if(stat is DoStat){
      sb.writeln('${stat.block},');
    }else if(stat is FuncCallStat){
      sb.write('{ kind:FuncCallStat, line:${stat.line},lastLine:${stat.lastLine},exp:');
      _expToStr(stat.exp, sb);
      sb.writeln('},');
    }else if(stat is WhileStat){
      sb.write('{ kind:WhileStat, line:${stat.line},lastLine:${stat.lastLine},exp:');
      _expToStr(stat.exp, sb);
      sb.write('block:${stat.block}');
      sb.writeln('},');
    }else if(stat is RepeatStat){
      sb.write('{ kind:RepeatStat, line:${stat.line},lastLine:${stat.lastLine},exp:');
      _expToStr(stat.exp, sb);
      sb.write('block:${stat.block}');
      sb.writeln('},');
    }else if(stat is IfStat){
      sb.write('{ kind:IfStat, line:${stat.line},lastLine:${stat.lastLine},exps:[');
      for(var st in stat.exps){
        _expToStr(st, sb);
      }
      sb.write('],\nblocks:[');

      for(var bloc in stat.blocks){
        sb.write('$bloc,');
      }
      sb.writeln(']},');
    }else if(stat is ForNumStat){

    }else if(stat is ForInStat){

    }else if(stat is LocalVarDeclStat){

    }else if(stat is AssignStat){

    }else if(stat is LocalFuncDefStat){

    }
  }
  
  _expToStr(Exp exp,StringBuffer sb){
    if(exp is NilExp){
      sb.writeln('{ kind:NilExp, line:${exp.line},lastLine:${exp.lastLine} },');
    }else if(exp is TrueExp){
      sb.writeln('{ kind:TrueExp, line:${exp.line},lastLine:${exp.lastLine} },');
    }else if(exp is FalseExp){
      sb.writeln('{ kind:FalseExp, line:${exp.line},lastLine:${exp.lastLine} },');
    }else if(exp is VarargExp){
      sb.writeln('{ kind:VarargExp, line:${exp.line},lastLine:${exp.lastLine} },');
    }else if(exp is IntegerExp){
      sb.writeln('{ kind:IntegerExp, line:${exp.line},lastLine:${exp.lastLine},val:${exp.val} },');
    }else if(exp is FloatExp){
      sb.writeln('{ kind:FloatExp, line:${exp.line},lastLine:${exp.lastLine},val:${exp.val} },');
    }else if(exp is StringExp){
      sb.writeln('{ kind:StringExp, line:${exp.line},lastLine:${exp.lastLine},str:${exp.str} },');
    }else if(exp is NameExp){
      sb.writeln('{ kind:NameExp, line:${exp.line},lastLine:${exp.lastLine},name:${exp.name} },');
    }else if(exp is UnopExp){
      sb.writeln('{ kind:UnopExp, line:${exp.line},lastLine:${exp.lastLine},op:${exp.op} },');
    }else if(exp is BinopExp){
      sb.writeln('{ kind:BinopExp, line:${exp.line},lastLine:${exp.lastLine},op:${exp.op} },');
    }else if(exp is ConcatExp){
      sb.writeln('{ kind:ConcatExp, line:${exp.line},lastLine:${exp.lastLine} },');
    }else if(exp is TableConstructorExp){
      sb.writeln('{ kind:TableConstructorExp, line:${exp.line},lastLine:${exp.lastLine} },');
    }else if(exp is FuncDefExp){
      sb.writeln('{ kind:FuncDefExp, line:${exp.line},lastLine:${exp.lastLine} },');
    }else if(exp is ParensExp){
      sb.writeln('{ kind:ParensExp, line:${exp.line},lastLine:${exp.lastLine} },');
    }else if(exp is TableAccessExp){
      sb.writeln('{ kind:TableAccessExp, line:${exp.line},lastLine:${exp.lastLine} },');
    }else if(exp is FuncCallExp){
      sb.writeln('{ kind:FuncCallExp, line:${exp.line},lastLine:${exp.lastLine} },');
    }
  }
}