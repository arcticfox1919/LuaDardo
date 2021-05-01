
import '../ast/block.dart';
import '../lexer/char_sequence.dart';
import '../lexer/lexer.dart';
import '../lexer/token.dart';
import 'block_parser.dart';

class Parser{

  static Block parse(String chunk, String chunkName) {
    Lexer lexer = Lexer(CharSequence(chunk), chunkName);
    Block block = BlockParser.parseBlock(lexer);
    lexer.nextTokenOfKind(TokenKind.TOKEN_EOF);
    return block;
  }
}