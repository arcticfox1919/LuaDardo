import '../ast/block.dart';
import '../ast/exp.dart';
import '../ast/stat.dart';
import '../lexer/lexer.dart';
import '../lexer/token.dart';
import 'block_parser.dart';
import 'exp_parser.dart';
import 'prefix_exp_parser.dart';

class StatParser {

  /*
    stat ::=  ‘;’
        | break
        | ‘::’ Name ‘::’
        | goto Name
        | do block end
        | while exp do block end
        | repeat block until exp
        | if exp then block {elseif exp then block} [else block] end
        | for Name ‘=’ exp ‘,’ exp [‘,’ exp] do block end
        | for namelist in explist do block end
        | function funcname funcbody
        | local function Name funcbody
        | local namelist [‘=’ explist]
        | varlist ‘=’ explist
        | functioncall
    */
  static Stat parseStat(Lexer lexer) {
    switch (lexer.LookAhead()) {
      case TokenKind.TOKEN_SEP_SEMI:    return parseEmptyStat(lexer);
      case TokenKind.TOKEN_KW_BREAK:    return parseBreakStat(lexer);
      case TokenKind.TOKEN_SEP_LABEL:   return parseLabelStat(lexer);
      case TokenKind.TOKEN_KW_GOTO:     return parseGotoStat(lexer);
      case TokenKind.TOKEN_KW_DO:       return parseDoStat(lexer);
      case TokenKind.TOKEN_KW_WHILE:    return parseWhileStat(lexer);
      case TokenKind.TOKEN_KW_REPEAT:   return parseRepeatStat(lexer);
      case TokenKind.TOKEN_KW_IF:       return parseIfStat(lexer);
      case TokenKind.TOKEN_KW_FOR:      return parseForStat(lexer);
      case TokenKind.TOKEN_KW_FUNCTION: return parseFuncDefStat(lexer);
      case TokenKind.TOKEN_KW_LOCAL:    return parseLocalAssignOrFuncDefStat(lexer);
      default:                return parseAssignOrFuncCallStat(lexer);
    }
  }

  // ;
   static EmptyStat parseEmptyStat(Lexer lexer) {
    lexer.nextTokenOfKind(TokenKind.TOKEN_SEP_SEMI);
    return EmptyStat.instance;
  }

  // break
   static BreakStat parseBreakStat(Lexer lexer) {
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_BREAK);
    return BreakStat(lexer.line);
  }

  // ‘::’ Name ‘::’
   static LabelStat parseLabelStat(Lexer lexer) {
    lexer.nextTokenOfKind(TokenKind.TOKEN_SEP_LABEL);          // ::
    String name = lexer.nextIdentifier().value; // name
    lexer.nextTokenOfKind(TokenKind.TOKEN_SEP_LABEL);          // ::
    return LabelStat(name);
  }

  // goto Name
   static GotoStat parseGotoStat(Lexer lexer) {
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_GOTO);            // goto
    String name = lexer.nextIdentifier().value; // name
    return GotoStat(name);
  }

  // do block end
   static DoStat parseDoStat(Lexer lexer) {
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_DO);  // do
    Block block = BlockParser.parseBlock(lexer);     // block
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_END); // end
    return DoStat(block);
  }

  // while exp do block end
   static WhileStat parseWhileStat(Lexer lexer) {
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_WHILE); // while
    Exp exp = ExpParser.parseExp(lexer);             // exp
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_DO);    // do
    Block block = BlockParser.parseBlock(lexer);       // block
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_END);   // end
    return WhileStat(exp, block);
  }

  // repeat block until exp
   static RepeatStat parseRepeatStat(Lexer lexer) {
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_REPEAT); // repeat
    Block block = BlockParser.parseBlock(lexer);        // block
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_UNTIL);  // until
    Exp exp = ExpParser.parseExp(lexer);              // exp
    return RepeatStat(block, exp);
  }

  // if exp then block {elseif exp then block} [else block] end
   static IfStat parseIfStat(Lexer lexer) {
    List<Exp> exps = List<Exp>();
    List<Block> blocks = List<Block>();

    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_IF);       // if
    exps.add(ExpParser.parseExp(lexer));                // exp
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_THEN);     // then
    blocks.add(BlockParser.parseBlock(lexer));            // block

    while (lexer.LookAhead() == TokenKind.TOKEN_KW_ELSEIF) {
      lexer.nextToken();                    // elseif
      exps.add(ExpParser.parseExp(lexer));            // exp
      lexer.nextTokenOfKind(TokenKind.TOKEN_KW_THEN); // then
      blocks.add(BlockParser.parseBlock(lexer));        // block
    }

    // else block => elseif true then block
    if (lexer.LookAhead() == TokenKind.TOKEN_KW_ELSE) {
      lexer.nextToken();                    // else
      exps.add(TrueExp(lexer.line));  //
      blocks.add(BlockParser.parseBlock(lexer));        // block
    }

    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_END);      // end
    return IfStat(exps, blocks);
  }

  // for Name ‘=’ exp ‘,’ exp [‘,’ exp] do block end
  // for namelist in explist do block end
   static Stat parseForStat(Lexer lexer) {
    int lineOfFor = lexer.nextTokenOfKind(TokenKind.TOKEN_KW_FOR).line;
    String name = lexer.nextIdentifier().value;
    if (lexer.LookAhead() == TokenKind.TOKEN_OP_ASSIGN) {
      return finishForNumStat(lexer, name, lineOfFor);
    } else {
      return finishForInStat(lexer, name);
    }
  }

  // for Name ‘=’ exp ‘,’ exp [‘,’ exp] do block end
   static ForNumStat finishForNumStat(Lexer lexer, String name, int lineOfFor) {
    ForNumStat stat = ForNumStat();
    stat.lineOfFor = lineOfFor;           // for
    stat.varName = name;                  // name

    lexer.nextTokenOfKind(TokenKind.TOKEN_OP_ASSIGN); // =
    stat.InitExp = ExpParser.parseExp(lexer);       // exp
    lexer.nextTokenOfKind(TokenKind.TOKEN_SEP_COMMA); // ,
    stat.LimitExp = ExpParser.parseExp(lexer);      // exp

    if (lexer.LookAhead() == TokenKind.TOKEN_SEP_COMMA) {
      lexer.nextToken();                  // ,
      stat.StepExp = ExpParser.parseExp(lexer);   // exp
    } else {
      stat.StepExp = IntegerExp(lexer.line, 1);
    }

    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_DO);     // do
    stat.lineOfDo = lexer.line;         //
    stat.block = BlockParser.parseBlock(lexer);       // block
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_END);    // end

    return stat;
  }

  // for namelist in explist do block end
  // namelist ::= Name {‘,’ Name}
  // explist ::= exp {‘,’ exp}
   static ForInStat finishForInStat(Lexer lexer, String name0) {
    ForInStat stat = ForInStat();
    // for
    stat.nameList =  finishNameList(lexer, name0); // namelist
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_IN);             // in
    stat.expList = ExpParser.parseExpList(lexer);           // explist
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_DO);             // do
    stat.lineOfDo = lexer.line;                 //
    stat.block = BlockParser.parseBlock(lexer);               // block
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_END);            // end

    return stat;
  }

  // namelist ::= Name {‘,’ Name}
   static List<String> finishNameList(Lexer lexer, String name0) {
    List<String> names = List<String>();
    names.add(name0);
    while (lexer.LookAhead() == TokenKind.TOKEN_SEP_COMMA) {
      lexer.nextToken();                            // ,
      names.add(lexer.nextIdentifier().value); // Name
    }
    return names;
  }

  // local function Name funcbody
  // local namelist [‘=’ explist]
   static Stat parseLocalAssignOrFuncDefStat(Lexer lexer) {
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_LOCAL);
    if (lexer.LookAhead() == TokenKind.TOKEN_KW_FUNCTION) {
      return finishLocalFuncDefStat(lexer);
    } else {
      return finishLocalVarDeclStat(lexer);
    }
  }

  /*
    http://www.lua.org/manual/5.3/manual.html#3.4.11

    function f() end          =>  f = function() end
    function t.a.b.c.f() end  =>  t.a.b.c.f = function() end
    function t.a.b.c:f() end  =>  t.a.b.c.f = function(self) end
    local function f() end    =>  local f; f = function() end

    The statement `local function f () body end`
    translates to `local f; f = function () body end`
    not to `local f = function () body end`
    (This only makes a difference when the body of the function
     contains references to f.)
    */
  // local function Name funcbody
   static LocalFuncDefStat finishLocalFuncDefStat(Lexer lexer) {
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_FUNCTION);        // local function
    String name = lexer.nextIdentifier().value; // name
    FuncDefExp fdExp = ExpParser.parseFuncDefExp(lexer);       // funcbody
    return LocalFuncDefStat(name, fdExp);
  }

  // local namelist [‘=’ explist]
   static LocalVarDeclStat finishLocalVarDeclStat(Lexer lexer) {
    String name0 = lexer.nextIdentifier().value;     // local Name
    List<String> nameList = finishNameList(lexer, name0); // { , Name }
    List<Exp> expList = null;
    if (lexer.LookAhead() == TokenKind.TOKEN_OP_ASSIGN) {
      lexer.nextToken();                                // ==
      expList = ExpParser.parseExpList(lexer);                    // explist
    }
    int lastLine = lexer.line;
    return LocalVarDeclStat(lastLine, nameList, expList);
  }

  // varlist ‘=’ explist
  // functioncall
   static Stat parseAssignOrFuncCallStat(Lexer lexer) {
    Exp prefixExp = PrefixExpParser.parsePrefixExp(lexer);
    if (prefixExp is FuncCallExp) {
      return FuncCallStat(prefixExp);
    } else {
      return parseAssignStat(lexer, prefixExp);
    }
  }

  // varlist ‘=’ explist |
   static AssignStat parseAssignStat(Lexer lexer, Exp var0) {
    List<Exp> varList = finishVarList(lexer, var0); // varlist
    lexer.nextTokenOfKind(TokenKind.TOKEN_OP_ASSIGN);         // =
    List<Exp> expList = ExpParser.parseExpList(lexer);        // explist
    int lastLine = lexer.line;
    return AssignStat(lastLine, varList, expList);
  }

  // varlist ::= var {‘,’ var}
   static List<Exp> finishVarList(Lexer lexer, Exp var0) {
    List<Exp> vars = List<Exp>();
    vars.add(checkVar(lexer, var0));               // var
    while (lexer.LookAhead() == TokenKind.TOKEN_SEP_COMMA) { // {
      lexer.nextToken();                         // ,
      Exp exp = PrefixExpParser.parsePrefixExp(lexer);           // var
      vars.add(checkVar(lexer, exp));            //
    }                                              // }
    return vars;
  }

  // var ::=  Name | prefixexp ‘[’ exp ‘]’ | prefixexp ‘.’ Name
   static Exp checkVar(Lexer lexer, Exp exp) {
    if (exp is NameExp || exp is TableAccessExp) {
      return exp;
    }
    lexer.nextTokenOfKind(null); // trigger error
    throw Exception("unreachable!");
  }

  // function funcname funcbody
  // funcname ::= Name {‘.’ Name} [‘:’ Name]
  // funcbody ::= ‘(’ [parlist] ‘)’ block end
  // parlist ::= namelist [‘,’ ‘...’] | ‘...’
  // namelist ::= Name {‘,’ Name}
   static AssignStat parseFuncDefStat(Lexer lexer) {
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_FUNCTION);     // function
    Map<Exp, bool> map = parseFuncName(lexer); // funcname
    Exp fnExp = map.keys.first;
    bool hasColon = map.values.first;
    FuncDefExp fdExp = ExpParser.parseFuncDefExp(lexer);    // funcbody
    if (hasColon) { // insert self
      if (fdExp.parList == null) {
        fdExp.parList = List<String>();
      }
      fdExp.parList.insert(0, "self");
    }

    return AssignStat(fdExp.lastLine,
        List<Exp>(1)..[0] = fnExp,
        List<Exp>(1)..[0] = fdExp);
  }

  // funcname ::= Name {‘.’ Name} [‘:’ Name]
   static Map<Exp, bool> parseFuncName(Lexer lexer) {
    Token id = lexer.nextIdentifier();
    Exp exp = NameExp(id.line, id.value);
    bool hasColon = false;

    while (lexer.LookAhead() == TokenKind.TOKEN_SEP_DOT) {
      lexer.nextToken();
      id = lexer.nextIdentifier();
      Exp idx = StringExp.fromToken(id);
      exp = TableAccessExp(id.line, exp, idx);
    }
    if (lexer.LookAhead() == TokenKind.TOKEN_SEP_COLON) {
      lexer.nextToken();
      id = lexer.nextIdentifier();
      Exp idx = StringExp.fromToken(id);
      exp = TableAccessExp(id.line, exp, idx);
      hasColon = true;
    }

    // workaround: return multiple values
    return Map<Exp, bool>()..[exp] = hasColon;
  }

}