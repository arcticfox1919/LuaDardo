import '../../number/lua_number.dart';
import '../ast/block.dart';
import '../ast/exp.dart';
import '../lexer/lexer.dart';
import '../lexer/token.dart';
import 'block_parser.dart';
import 'optimizer.dart';
import 'prefix_exp_parser.dart';

class ExpParser {

  // explist ::= exp {‘,’ exp}
  static List<Exp> parseExpList(Lexer lexer) {
    List<Exp> exps =  List<Exp>();
    exps.add(parseExp(lexer));
    while (lexer.LookAhead() == TokenKind.TOKEN_SEP_COMMA) {
      lexer.nextToken();
      exps.add(parseExp(lexer));
    }
    return exps;
  }

  /*
    exp ::=  nil | false | true | Numeral | LiteralString | ‘...’ | functiondef |
         prefixexp | tableconstructor | exp binop exp | unop exp
    */
  /*
    exp   ::= exp12
    exp12 ::= exp11 {or exp11}
    exp11 ::= exp10 {and exp10}
    exp10 ::= exp9 {(‘<’ | ‘>’ | ‘<=’ | ‘>=’ | ‘~=’ | ‘==’) exp9}
    exp9  ::= exp8 {‘|’ exp8}
    exp8  ::= exp7 {‘~’ exp7}
    exp7  ::= exp6 {‘&’ exp6}
    exp6  ::= exp5 {(‘<<’ | ‘>>’) exp5}
    exp5  ::= exp4 {‘..’ exp4}
    exp4  ::= exp3 {(‘+’ | ‘-’ | ‘*’ | ‘/’ | ‘//’ | ‘%’) exp3}
    exp2  ::= {(‘not’ | ‘#’ | ‘-’ | ‘~’)} exp1
    exp1  ::= exp0 {‘^’ exp2}
    exp0  ::= nil | false | true | Numeral | LiteralString
            | ‘...’ | functiondef | prefixexp | tableconstructor
    */
  static Exp parseExp(Lexer lexer) {
    return parseExp12(lexer);
  }


  // x or y
   static Exp parseExp12(Lexer lexer) {
    Exp exp = parseExp11(lexer);
    while (lexer.LookAhead() == TokenKind.TOKEN_OP_OR) {
      Token op = lexer.nextToken();
      BinopExp lor = BinopExp(op, exp, parseExp11(lexer));
      exp = Optimizer.optimizeLogicalOr(lor);
    }
    return exp;
  }

  // x and y
   static Exp parseExp11(Lexer lexer) {
    Exp exp = parseExp10(lexer);
    while (lexer.LookAhead() == TokenKind.TOKEN_OP_AND) {
      Token op = lexer.nextToken();
      BinopExp land = BinopExp(op, exp, parseExp10(lexer));
      exp = Optimizer.optimizeLogicalAnd(land);
    }
    return exp;
  }

  // compare
   static Exp parseExp10(Lexer lexer) {
    Exp exp = parseExp9(lexer);
    while (true) {
      switch (lexer.LookAhead()) {
        case TokenKind.TOKEN_OP_LT:
        case TokenKind.TOKEN_OP_GT:
        case TokenKind.TOKEN_OP_NE:
        case TokenKind.TOKEN_OP_LE:
        case TokenKind.TOKEN_OP_GE:
        case TokenKind.TOKEN_OP_EQ:
          Token op = lexer.nextToken();
          exp = BinopExp(op, exp, parseExp9(lexer));
          break;
        default:
          return exp;
      }
    }
  }

  // x | y
   static Exp parseExp9(Lexer lexer) {
    Exp exp = parseExp8(lexer);
    while (lexer.LookAhead() == TokenKind.TOKEN_OP_BOR) {
      Token op = lexer.nextToken();
      BinopExp bor = BinopExp(op, exp, parseExp8(lexer));
      exp = Optimizer.optimizeBitwiseBinaryOp(bor);
    }
    return exp;
  }

  // x ~ y
   static Exp parseExp8(Lexer lexer) {
    Exp exp = parseExp7(lexer);
    while (lexer.LookAhead() == TokenKind.TOKEN_OP_WAVE) {
      Token op = lexer.nextToken();
      BinopExp bxor = BinopExp(op, exp, parseExp7(lexer));
      exp = Optimizer.optimizeBitwiseBinaryOp(bxor);
    }
    return exp;
  }

  // x & y
   static Exp parseExp7(Lexer lexer) {
    Exp exp = parseExp6(lexer);
    while (lexer.LookAhead() == TokenKind.TOKEN_OP_BAND) {
      Token op = lexer.nextToken();
      BinopExp band = BinopExp(op, exp, parseExp6(lexer));
      exp = Optimizer.optimizeBitwiseBinaryOp(band);
    }
    return exp;
  }

  // shift
   static Exp parseExp6(Lexer lexer) {
    Exp exp = parseExp5(lexer);
    while (true) {
      switch (lexer.LookAhead()) {
        case TokenKind.TOKEN_OP_SHL:
        case TokenKind.TOKEN_OP_SHR:
          Token op = lexer.nextToken();
          BinopExp shx = BinopExp(op, exp, parseExp5(lexer));
          exp = Optimizer.optimizeBitwiseBinaryOp(shx);
          break;
        default:
          return exp;
      }
    }
  }

  // a .. b
   static Exp parseExp5(Lexer lexer) {
    Exp exp = parseExp4(lexer);
    if (lexer.LookAhead() != TokenKind.TOKEN_OP_CONCAT) {
      return exp;
    }

    List<Exp> exps = List<Exp>();
    exps.add(exp);
    int line = 0;
    while (lexer.LookAhead() == TokenKind.TOKEN_OP_CONCAT) {
      line = lexer.nextToken().line;
      exps.add(parseExp4(lexer));
    }
    return ConcatExp(line, exps);
  }

  // x +/- y
   static Exp parseExp4(Lexer lexer) {
    Exp exp = parseExp3(lexer);
    while (true) {
      switch (lexer.LookAhead()) {
        case TokenKind.TOKEN_OP_ADD:
        case TokenKind.TOKEN_OP_MINUS:
          Token op = lexer.nextToken();
          BinopExp arith = BinopExp(op, exp, parseExp3(lexer));
          exp = Optimizer.optimizeArithBinaryOp(arith);
          break;
        default:
          return exp;
      }
    }
  }

  // *, %, /, //
   static Exp parseExp3(Lexer lexer) {
    Exp exp = parseExp2(lexer);
    while (true) {
      switch (lexer.LookAhead()) {
        case TokenKind.TOKEN_OP_MUL:
        case TokenKind.TOKEN_OP_MOD:
        case TokenKind.TOKEN_OP_DIV:
        case TokenKind.TOKEN_OP_IDIV:
          Token op = lexer.nextToken();
          BinopExp arith = BinopExp(op, exp, parseExp2(lexer));
          exp = Optimizer.optimizeArithBinaryOp(arith);
          break;
        default:
          return exp;
      }
    }
  }

  // unary
   static Exp parseExp2(Lexer lexer) {
    switch (lexer.LookAhead()) {
      case TokenKind.TOKEN_OP_MINUS:
      case TokenKind.TOKEN_OP_WAVE:
      case TokenKind.TOKEN_OP_LEN:
      case TokenKind.TOKEN_OP_NOT:
        Token op = lexer.nextToken();
        UnopExp exp = UnopExp(op, parseExp2(lexer));
        return Optimizer.optimizeUnaryOp(exp);
    }
    return parseExp1(lexer);
  }

  // x ^ y
   static Exp parseExp1(Lexer lexer) { // pow is right associative
    Exp exp = parseExp0(lexer);
    if (lexer.LookAhead() == TokenKind.TOKEN_OP_POW) {
      Token op = lexer.nextToken();
      exp = BinopExp(op, exp, parseExp2(lexer));
    }
    return Optimizer.optimizePow(exp);
  }

   static Exp parseExp0(Lexer lexer) {
    switch (lexer.LookAhead()) {
      case TokenKind.TOKEN_VARARG: // ...
        return VarargExp(lexer.nextToken().line);
      case TokenKind.TOKEN_KW_NIL: // nil
        return NilExp(lexer.nextToken().line);
      case TokenKind.TOKEN_KW_TRUE: // true
        return TrueExp(lexer.nextToken().line);
      case TokenKind.TOKEN_KW_FALSE: // false
        return FalseExp(lexer.nextToken().line);
      case TokenKind.TOKEN_STRING: // LiteralString
        return StringExp.fromToken(lexer.nextToken());
      case TokenKind.TOKEN_NUMBER: // Numeral
        return parseNumberExp(lexer);
      case TokenKind.TOKEN_SEP_LCURLY: // tableconstructor
        return parseTableConstructorExp(lexer);
      case TokenKind.TOKEN_KW_FUNCTION: // functiondef
        lexer.nextToken();
        return parseFuncDefExp(lexer);
      default: // prefixexp
        return PrefixExpParser.parsePrefixExp(lexer);
    }
  }

   static Exp parseNumberExp(Lexer lexer) {
    Token token = lexer.nextToken();
    int i = LuaNumber.parseInteger(token.value);
    if (i != null) {
      return IntegerExp(token.line, i);
    }
    double f = LuaNumber.parseFloat(token.value);
    if (f != null) {
      return FloatExp(token.line, f);
    }
    throw Exception("not a number: $token");
  }

  // functiondef ::= function funcbody
  // funcbody ::= ‘(’ [parlist] ‘)’ block end
  static FuncDefExp parseFuncDefExp(Lexer lexer) {
    int line = lexer.line;                    // function
    lexer.nextTokenOfKind(TokenKind.TOKEN_SEP_LPAREN);    // (
    List<String> parList = parseParList(lexer); // [parlist]
    lexer.nextTokenOfKind(TokenKind.TOKEN_SEP_RPAREN);    // )
    Block block = BlockParser.parseBlock(lexer);            // block
    lexer.nextTokenOfKind(TokenKind.TOKEN_KW_END);        // end
    int lastLine = lexer.line;

    FuncDefExp fdExp = FuncDefExp();
    fdExp.line = line;
    fdExp.lastLine = lastLine;
    fdExp.IsVararg = parList.remove("...");
    fdExp.parList = parList;
    fdExp.block = block;
    return fdExp;
  }

  // [parlist]
  // parlist ::= namelist [‘,’ ‘...’] | ‘...’
   static List<String> parseParList(Lexer lexer) {
    List<String> names = List<String>();

    switch (lexer.LookAhead()) {
      case TokenKind.TOKEN_SEP_RPAREN:
        return names;
      case TokenKind.TOKEN_VARARG:
        lexer.nextToken();
        names.add("...");
        return names;
    }

    names.add(lexer.nextIdentifier().value);
    while (lexer.LookAhead() == TokenKind.TOKEN_SEP_COMMA) {
      lexer.nextToken();
      if (lexer.LookAhead() == TokenKind.TOKEN_IDENTIFIER) {
        names.add(lexer.nextIdentifier().value);
      } else {
        lexer.nextTokenOfKind(TokenKind.TOKEN_VARARG);
        names.add("...");
        break;
      }
    }

    return names;
  }

  // tableconstructor ::= ‘{’ [fieldlist] ‘}’
  static TableConstructorExp parseTableConstructorExp(Lexer lexer) {
    TableConstructorExp tcExp = TableConstructorExp();
    tcExp.line = lexer.line;
    lexer.nextTokenOfKind(TokenKind.TOKEN_SEP_LCURLY); // {
    parseFieldList(lexer, tcExp);            // [fieldlist]
    lexer.nextTokenOfKind(TokenKind.TOKEN_SEP_RCURLY); // }
    tcExp.lastLine = lexer.line;
    return tcExp;
  }

  // fieldlist ::= field {fieldsep field} [fieldsep]
   static void parseFieldList(Lexer lexer, TableConstructorExp tcExp) {
    if (lexer.LookAhead() != TokenKind.TOKEN_SEP_RCURLY) {
      parseField(lexer, tcExp);

      while (isFieldSep(lexer.LookAhead())) {
        lexer.nextToken();
        if (lexer.LookAhead() != TokenKind.TOKEN_SEP_RCURLY) {
          parseField(lexer, tcExp);
        } else {
          break;
        }
      }
    }
  }

  // fieldsep ::= ‘,’ | ‘;’
   static bool isFieldSep(TokenKind kind) {
    return kind == TokenKind.TOKEN_SEP_COMMA || kind == TokenKind.TOKEN_SEP_SEMI;
  }

  // field ::= ‘[’ exp ‘]’ ‘=’ exp | Name ‘=’ exp | exp
   static void parseField(Lexer lexer, TableConstructorExp tcExp) {
    if (lexer.LookAhead() == TokenKind.TOKEN_SEP_LBRACK) {
      lexer.nextToken();                       // [
      tcExp.keyExps.add(parseExp(lexer));           // exp
      lexer.nextTokenOfKind(TokenKind.TOKEN_SEP_RBRACK); // ]
      lexer.nextTokenOfKind(TokenKind.TOKEN_OP_ASSIGN);  // =
      tcExp.valExps.add(parseExp(lexer));           // exp
      return;
    }

    Exp exp = parseExp(lexer);
    if (exp is NameExp) {
      if (lexer.LookAhead() == TokenKind.TOKEN_OP_ASSIGN) {
        // Name ‘=’ exp => ‘[’ LiteralString ‘]’ = exp
        tcExp.keyExps.add(StringExp(exp.line, exp.name));
        lexer.nextToken();
        tcExp.valExps.add(parseExp(lexer));
        return;
      }
    }

    tcExp.keyExps.add(null);
    tcExp.valExps.add(exp);
  }

}