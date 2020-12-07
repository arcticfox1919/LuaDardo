import '../ast/exp.dart';
import '../lexer/lexer.dart';
import '../lexer/token.dart';
import 'exp_parser.dart';

class PrefixExpParser {

  /*
    prefixexp ::= Name
        | ‘(’ exp ‘)’
        | prefixexp ‘[’ exp ‘]’
        | prefixexp ‘.’ Name
        | prefixexp [‘:’ Name] args
    */
  static Exp parsePrefixExp(Lexer lexer) {
    Exp exp;
    if (lexer.LookAhead() == TokenKind.TOKEN_IDENTIFIER) {
      Token id = lexer.nextIdentifier(); // Name
      exp = NameExp(id.line, id.value);
    } else { // ‘(’ exp ‘)’
      exp = parseParensExp(lexer);
    }
    return finishPrefixExp(lexer, exp);
  }

  static Exp parseParensExp(Lexer lexer) {
    lexer.nextTokenOfKind(TokenKind.TOKEN_SEP_LPAREN); // (
    Exp exp = ExpParser.parseExp(lexer);               // exp
    lexer.nextTokenOfKind(TokenKind.TOKEN_SEP_RPAREN); // )

    if (exp is VarargExp
    || exp is FuncCallExp
    || exp is NameExp
    || exp is TableAccessExp) {
      return ParensExp(exp);
    }

    // no need to keep parens
    return exp;
  }

  static Exp finishPrefixExp(Lexer lexer, Exp exp) {
    while (true) {
      switch (lexer.LookAhead()) {
        case TokenKind.TOKEN_SEP_LBRACK: { // prefixexp ‘[’ exp ‘]’
          lexer.nextToken();                       // ‘[’
          Exp keyExp = ExpParser.parseExp(lexer);            // exp
          lexer.nextTokenOfKind(TokenKind.TOKEN_SEP_RBRACK); // ‘]’
          exp = TableAccessExp(lexer.line, exp, keyExp);
          break;
        }
        case TokenKind.TOKEN_SEP_DOT: { // prefixexp ‘.’ Name
          lexer.nextToken();                   // ‘.’
          Token name = lexer.nextIdentifier(); // Name
          Exp keyExp = StringExp.fromToken(name);
          exp = TableAccessExp(name.line, exp, keyExp);
          break;
        }
        case TokenKind.TOKEN_SEP_COLON: // prefixexp ‘:’ Name args
        case TokenKind.TOKEN_SEP_LPAREN:
        case TokenKind.TOKEN_SEP_LCURLY:
        case TokenKind.TOKEN_STRING: // prefixexp args
          exp = finishFuncCallExp(lexer, exp);
          break;
        default:
          return exp;
      }
    }
  }

  // functioncall ::=  prefixexp args | prefixexp ‘:’ Name args
  static FuncCallExp finishFuncCallExp(Lexer lexer, Exp prefixExp) {
    FuncCallExp fcExp = FuncCallExp();
    fcExp.prefixExp = prefixExp;
    fcExp.nameExp = parseNameExp(lexer);
    fcExp.line = lexer.line; // todo
    fcExp.args = parseArgs(lexer);
    fcExp.lastLine = lexer.line;
    return fcExp;
  }

  static StringExp parseNameExp(Lexer lexer) {
    if (lexer.LookAhead() == TokenKind.TOKEN_SEP_COLON) {
      lexer.nextToken();
      Token name = lexer.nextIdentifier();
      return StringExp.fromToken(name);
    }
    return null;
  }

  // args ::=  ‘(’ [explist] ‘)’ | tableconstructor | LiteralString
  static List<Exp> parseArgs(Lexer lexer) {
    switch (lexer.LookAhead()) {
      case TokenKind.TOKEN_SEP_LPAREN: // ‘(’ [explist] ‘)’
        lexer.nextToken(); // TOKEN_SEP_LPAREN
        List<Exp> args = null;
        if (lexer.LookAhead() != TokenKind.TOKEN_SEP_RPAREN) {
          args = ExpParser.parseExpList(lexer);
        }
        lexer.nextTokenOfKind(TokenKind.TOKEN_SEP_RPAREN);
        return args;
      case TokenKind.TOKEN_SEP_LCURLY: // ‘{’ [fieldlist] ‘}’
        return List<Exp>(1)..[0] = ExpParser.parseTableConstructorExp(lexer);
      default: // LiteralString
        Token str = lexer.nextTokenOfKind(TokenKind.TOKEN_STRING);
        return List<Exp>(1)..[0] = StringExp.fromToken(str);
    }
  }

}