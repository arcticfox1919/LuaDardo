import '../ast/block.dart';
import '../ast/exp.dart';
import '../ast/stat.dart';
import '../lexer/lexer.dart';
import '../lexer/token.dart';
import 'exp_parser.dart';
import 'stat_parser.dart';

class BlockParser {

  // block ::= {stat} [retstat]
  static Block parseBlock(Lexer lexer) {
    Block block = Block();
    block.stats = parseStats(lexer);
    block.retExps = parseRetExps(lexer);
    block.lastLine = lexer.line;
    return block;
  }

   static List<Stat> parseStats(Lexer lexer) {
    List<Stat> stats = List<Stat>();
    while (!_isReturnOrBlockEnd(lexer.LookAhead())) {
      Stat stat = StatParser.parseStat(lexer);
      if (!(stat is EmptyStat)) {
        stats.add(stat);
      }
    }
    return stats;
  }

   static bool _isReturnOrBlockEnd(TokenKind kind) {
    switch (kind) {
      case TokenKind.TOKEN_KW_RETURN:
      case TokenKind.TOKEN_EOF:
      case TokenKind.TOKEN_KW_END:
      case TokenKind.TOKEN_KW_ELSE:
      case TokenKind.TOKEN_KW_ELSEIF:
      case TokenKind.TOKEN_KW_UNTIL:
        return true;
      default:
        return false;
    }
  }

  // retstat ::= return [explist] [‘;’]
  // explist ::= exp {‘,’ exp}
   static List<Exp> parseRetExps(Lexer lexer) {
    if (lexer.LookAhead() != TokenKind.TOKEN_KW_RETURN) {
      return null;
    }

    lexer.nextToken();
    switch (lexer.LookAhead()) {
      case TokenKind.TOKEN_EOF:
      case TokenKind.TOKEN_KW_END:
      case TokenKind.TOKEN_KW_ELSE:
      case TokenKind.TOKEN_KW_ELSEIF:
      case TokenKind.TOKEN_KW_UNTIL:
        return const <Exp>[];
      case TokenKind.TOKEN_SEP_SEMI:
        lexer.nextToken();
        return const <Exp>[];
      default:
        List<Exp> exps = ExpParser.parseExpList(lexer);
        if (lexer.LookAhead() == TokenKind.TOKEN_SEP_SEMI) {
          lexer.nextToken();
        }
        return exps;
    }
  }

}