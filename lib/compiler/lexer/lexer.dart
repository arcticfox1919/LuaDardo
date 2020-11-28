import 'char_sequence.dart';
import 'escaper.dart';
import 'token.dart';


/// 词法分析器
class Lexer {
  static final reNewLine = RegExp("\r\n|\n\r|\n|\r");
  static final reIdentifier = RegExp("^[_\\d\\w]+");
  static final reNumber = RegExp("^0[xX][0-9a-fA-F]*(\\.[0-9a-fA-F]*)?([pP][+\\-]?[0-9]+)?|^[0-9]*(\\.[0-9]*)?([eE][+\\-]?[0-9]+)?");
  static final reShortStr = RegExp(r'''(^'(\\\\|\\'|\\\n|\\z\s*|[^'\n])*')|(^"(\\\\|\\"|\\\n|\\z\s*|[^"\n])*")''');
  static final reOpeningLongBracket = RegExp("^\\[=*\\[");

  /// 源码
  CharSequence chunk;
  /// 源文件名
  String chunkName;
  /// 当前行号
  int line;

  // to support lookahead
  Token cachedNextToken;
  int lineBackup;

  Lexer(this.chunk,this.chunkName):this.line=1;

  TokenKind LookAhead() {
    if (cachedNextToken == null) {
      lineBackup = line;
      cachedNextToken = nextToken();
    }
    return cachedNextToken.kind;
  }

  Token nextTokenOfKind(TokenKind kind) {
    Token token = nextToken();
    if (token.kind != kind) {
      error("syntax error near '${token.value}'");
    }
    return token;
  }

  Token nextIdentifier() {
    return nextTokenOfKind(TokenKind.TOKEN_IDENTIFIER);
  }

  Token nextToken() {
    if (cachedNextToken != null) {
      Token token = cachedNextToken;
      cachedNextToken = null;
      return token;
    }

    skipWhiteSpaces();
    if (chunk.length <= 0) {
      return Token(line, TokenKind.TOKEN_EOF, "EOF");
    }

    switch (chunk.charAt(0)) {
      case ';': chunk.next(1); return  Token(line, TokenKind.TOKEN_SEP_SEMI,   ";");
      case ',': chunk.next(1); return  Token(line, TokenKind.TOKEN_SEP_COMMA,  ",");
      case '(': chunk.next(1); return  Token(line, TokenKind.TOKEN_SEP_LPAREN, "(");
      case ')': chunk.next(1); return  Token(line, TokenKind.TOKEN_SEP_RPAREN, ")");
      case ']': chunk.next(1); return  Token(line, TokenKind.TOKEN_SEP_RBRACK, "]");
      case '{': chunk.next(1); return  Token(line, TokenKind.TOKEN_SEP_LCURLY, "{");
      case '}': chunk.next(1); return  Token(line, TokenKind.TOKEN_SEP_RCURLY, "}");
      case '+': chunk.next(1); return  Token(line, TokenKind.TOKEN_OP_ADD,     "+");
      case '-': chunk.next(1); return  Token(line, TokenKind.TOKEN_OP_MINUS,   "-");
      case '*': chunk.next(1); return  Token(line, TokenKind.TOKEN_OP_MUL,     "*");
      case '^': chunk.next(1); return  Token(line, TokenKind.TOKEN_OP_POW,     "^");
      case '%': chunk.next(1); return  Token(line, TokenKind.TOKEN_OP_MOD,     "%");
      case '&': chunk.next(1); return  Token(line, TokenKind.TOKEN_OP_BAND,    "&");
      case '|': chunk.next(1); return  Token(line, TokenKind.TOKEN_OP_BOR,     "|");
      case '#': chunk.next(1); return  Token(line, TokenKind.TOKEN_OP_LEN,     "#");
      case ':':
        if (chunk.startsWith("::")) {
          chunk.next(2);
          return  Token(line, TokenKind.TOKEN_SEP_LABEL, "::");
        } else {
          chunk.next(1);
          return  Token(line, TokenKind.TOKEN_SEP_COLON, ":");
        }
        break;
      case '/':
        if (chunk.startsWith("//")) {
          chunk.next(2);
          return  Token(line, TokenKind.TOKEN_OP_IDIV, "//");
        } else {
          chunk.next(1);
          return  Token(line, TokenKind.TOKEN_OP_DIV, "/");
        }
        break;
      case '~':
        if (chunk.startsWith("~=")) {
          chunk.next(2);
          return  Token(line, TokenKind.TOKEN_OP_NE, "~=");
        } else {
          chunk.next(1);
          return  Token(line, TokenKind.TOKEN_OP_WAVE, "~");
        }
        break;
      case '=':
        if (chunk.startsWith("==")) {
          chunk.next(2);
          return  Token(line, TokenKind.TOKEN_OP_EQ, "==");
        } else {
          chunk.next(1);
          return  Token(line, TokenKind.TOKEN_OP_ASSIGN, "=");
        }
        break;
      case '<':
        if (chunk.startsWith("<<")) {
          chunk.next(2);
          return  Token(line, TokenKind.TOKEN_OP_SHL, "<<");
        } else if (chunk.startsWith("<=")) {
          chunk.next(2);
          return  Token(line, TokenKind.TOKEN_OP_LE, "<=");
        } else {
          chunk.next(1);
          return  Token(line, TokenKind.TOKEN_OP_LT, "<");
        }
        break;
      case '>':
        if (chunk.startsWith(">>")) {
          chunk.next(2);
          return  Token(line, TokenKind.TOKEN_OP_SHR, ">>");
        } else if (chunk.startsWith(">=")) {
          chunk.next(2);
          return  Token(line, TokenKind.TOKEN_OP_GE, ">=");
        } else {
          chunk.next(1);
          return  Token(line, TokenKind.TOKEN_OP_GT, ">");
        }
        break;
      case '.':
        if (chunk.startsWith("...")) {
          chunk.next(3);
          return  Token(line, TokenKind.TOKEN_VARARG, "...");
        } else if (chunk.startsWith("..")) {
          chunk.next(2);
          return  Token(line, TokenKind.TOKEN_OP_CONCAT, "..");
        } else if (chunk.length == 1 || !CharSequence.isDigit(chunk.charAt(1))) {
          chunk.next(1);
          return  Token(line, TokenKind.TOKEN_SEP_DOT, ".");
        }
        break;
      case '[':
        if (chunk.startsWith("[[") || chunk.startsWith("[=")) {
          return  Token(line, TokenKind.TOKEN_STRING, scanLongString());
        } else {
          chunk.next(1);
          return  Token(line, TokenKind.TOKEN_SEP_LBRACK, "[");
        }
        break;
      case '\'':
      case '"':
        return  Token(line, TokenKind.TOKEN_STRING, scanShortString());
    }

    String c = chunk.charAt(0);
    if (c == '.' || CharSequence.isDigit(c)) {
      return  Token(line, TokenKind.TOKEN_NUMBER, scanNumber());
    }
    if (c == '_' || CharSequence.isLetter(c)) {
      String id = scanIdentifier();
      return keywords.containsKey(id)
          ?  Token(line, keywords[id], id)
          :  Token(line, TokenKind.TOKEN_IDENTIFIER, id);
    }

    return error("unexpected symbol near $c");
  }

  void skipWhiteSpaces() {
    while (chunk.length > 0) {
      if (chunk.startsWith("--")) {
        skipComment();
      } else if (chunk.startsWith("\r\n") || chunk.startsWith("\n\r")) {
        chunk.next(2);
        line += 1;
      } else if (CharSequence.isNewLine(chunk.charAt(0))) {
        chunk.next(1);
        line += 1;
      } else if(CharSequence.isWhiteSpace(chunk.charAt(0))) {
        chunk.next(1);
      } else {
        break;
      }
    }
  }

  void skipComment() {
    chunk.next(2); // skip --

    // long comment ?
    if (chunk.startsWith("[")) {
      if (chunk.find(reOpeningLongBracket) != null) {
        scanLongString();
        return;
      }
    }

    // short comment
    while(chunk.length > 0 && !CharSequence.isNewLine(chunk.charAt(0))) {
      chunk.next(1);
    }
  }

  String scan(Pattern pattern) {
    String token = chunk.find(pattern);
    if (token == null) {
      throw Exception("unreachable!");
    }
    chunk.next(token.length);
    return token;
  }

  String scanLongString() {
    String openingLongBracket = chunk.find(reOpeningLongBracket);
    if (openingLongBracket == null) {
      return error("invalid long string delimiter near '${chunk.substring(0, 2)}'");
    }

    String closingLongBracket = openingLongBracket.replaceAll("[", "]");
    int closingLongBracketIdx = chunk.indexOf(closingLongBracket);
    if (closingLongBracketIdx < 0) {
      return error("unfinished long string or comment");
    }

    String str = chunk.substring(openingLongBracket.length, closingLongBracketIdx);
    chunk.next(closingLongBracketIdx + closingLongBracket.length);

    str = str.replaceAll(reNewLine, "\n");
    // str = reNewLine.matcher(str).replaceAll("\n");
    line += CharSequence.count(str, "\n");
    if (str.startsWith("\n")) {
      str = str.substring(1);
    }

    return str;
  }

  String scanShortString() {
    String str = chunk.find(reShortStr);
    if (str != null) {
      chunk.next(str.length);
      str = str.substring(1, str.length - 1);
      if (str.indexOf('\\') >= 0) {
        line += str.split(reNewLine).length-1;
        // line += reNewLine.split(str).length - 1;
        str = Escaper(str, this).escape();
      }
      return str;
    }
    return error("unfinished string");
  }

  String scanIdentifier() {
    return scan(reIdentifier);
  }

  String scanNumber() {
    return scan(reNumber);
  }

  int _line() {
    return cachedNextToken != null ? lineBackup : line;
  }

  error(String msg) {
    throw Exception("$chunkName:${_line()} $msg");
  }
}
