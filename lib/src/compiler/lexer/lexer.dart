import 'char_sequence.dart';
import 'token.dart';


/// 词法分析器
class Lexer {

  /// 源码
  CharSequence chunk;
  /// 源文件名
  String chunkName;
  /// 当前行号
  int line;

  // to support lookahead
  Token cachedNextToken;
  int lineBackup;

  StringBuffer _buff = StringBuffer();

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

    _buff.clear();
    switch (chunk.current) {
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
        } else if (chunk.length == 1) {
          chunk.next(1);
          return  Token(line, TokenKind.TOKEN_SEP_DOT, ".");
        }else if(!CharSequence.isDigit(chunk.charAt(1))){
          chunk.next(1);
          return  Token(line, TokenKind.TOKEN_SEP_DOT, ".");
        }else{  // is digit
          return Token(line, TokenKind.TOKEN_NUMBER, readNumeral());
        }
        break;
      case '[':  // long string or simply '['
        int sep = _skip_sep();
        if (sep >= 0) {
          return Token(line, TokenKind.TOKEN_STRING, readLongString(true, sep));
        } else if (sep == -1)
          return Token(line, TokenKind.TOKEN_SEP_LBRACK, "[");
        else error("invalid long string delimiter");

        break;
      case '\'':
      case '"':
        return  Token(line, TokenKind.TOKEN_STRING, readString());
    }

    if (CharSequence.isDigit(chunk.current)) {
      return Token(line, TokenKind.TOKEN_NUMBER, readNumeral());
    }

    if (chunk.current == '_' || CharSequence.isLetter(chunk.current)) {
      do {
        _save_and_next();
      } while (CharSequence.isalnum(chunk.current) || chunk.current == '_');
      String id = _buff.toString();
      return keywords.containsKey(id)
          ?  Token(line, keywords[id], id)
          :  Token(line, TokenKind.TOKEN_IDENTIFIER, id);
    }

    return error("unexpected symbol near ${chunk.current}");
  }

  void skipWhiteSpaces() {
    while (chunk.length > 0) {
      if (chunk.startsWith("--")) {
        skipComment();
      } else if (chunk.startsWith("\r\n") || chunk.startsWith("\n\r")) {
        chunk.next(2);
        line += 1;
      } else if (CharSequence.isNewLine(chunk.current)) {
        chunk.next(1);
        line += 1;
      } else if(CharSequence.isWhiteSpace(chunk.current)) {
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
      int sep = _skip_sep();
      _buff.clear(); /* `skip_sep' 可能会弄脏缓冲区 */
      if (sep >= 0) {
        readLongString(false, sep);  /* long comment */
        _buff.clear();
        return;
      }
    }

    // short comment
    while(chunk.length > 0 && !CharSequence.isNewLine(chunk.current)) {
      chunk.next(1);
    }
  }

  void _save() {
    _buff.write(chunk.current);
  }

  void _save_c(int c) {
    _buff.writeCharCode(c);
  }

  void _save_and_next(){
    _save();
    chunk.next(1);
  }

  void _incLineNumber() {
    String old = chunk.current;
    chunk.next(1); // skip '\n' or '\r'
    if (CharSequence.isNewLine(chunk.current) && chunk.current != old) {
      chunk.next(1); // skip '\n\r' or '\r\n'
    }
    if (++line < 0) { // overflow
      error("chunk has too many lines");
    }
  }

  String readString() {
    String del = chunk.current;
    _save_and_next();
    while (chunk.current != del) {
      switch (chunk.current) {
        // EOZ
        case '': error("unfinished string"); break;
        case '\n':
        case '\r':
          error("unfinished string");
          continue;
        case '\\':
        {
            int c;
            // do not save the '\'
            chunk.next(1);
            switch (chunk.current) {
              case 'a':
                c = 7;  // '\a'
                break;
              case 'b':
                c = 8;  // '\b'
                break;
              case 'f':
                c = 12; // '\f'
                break;
              case 'n':
                c = 10; // '\n'
                break;
              case 'r':
                c = 13; // '\r'
                break;
              case 't':
                c = 9;  // '\t'
                break;
              case 'v':
                c = 11; // '\v'
                break;
              case 'x': // '\xXX'
                var hex = chunk.substring(1, 3);
                if(CharSequence.isxDigit(hex)){
                  _save_c(int.parse(hex, radix: 16));
                  chunk.next(3);
                  continue;
                }else error("hexadecimal digit expected");
                break;
              case 'u': // '\u{XXX}'
                chunk.next(1);
                if(chunk.current != '{') error("missing '{'");

                int j = 1;
                while(CharSequence.isxDigit(chunk.charAt(j))) j++;

                if(chunk.charAt(j) != '}') error("missing '}'");
                var seq = chunk.substring(1, j);
                int d = int.parse(seq, radix: 16);
                if (d <= 0x10FFFF) {
                  _save_c(d);
                  chunk.next(j+1);
                }else error("UTF-8 value too large near '$seq'");
                continue;
              case '\n': case '\r':
                _save_c(10); // write '\n'
                _incLineNumber();
                continue;
              case '\\': case '"': case '\'':
                _save_and_next();
                continue;
              case '': // EOZ
                continue; // will raise an error next loop
              case 'z':    // zap following span of spaces
                chunk.next(1);
                while (chunk.length > 0 &&
                    CharSequence.isWhiteSpace(chunk.current)) {
                  if(CharSequence.isNewLine(chunk.current)) _incLineNumber();
                  else chunk.next(1);
                }
                continue;
              default:
                if (!CharSequence.isDigit(chunk.current)) {
                  error("invalid escape sequence near '\\${chunk.current}'");
                } else {  // digital escape '\ddd'
                  c = 0;
                  /* 最多读取3位数字 */
                  for (int i = 0; i < 3 && CharSequence.isDigit(chunk.current); i++) {
                    c = 10 * c + (chunk.current - '0');
                      chunk.next(1);
                  }
                  _save_c(c);
                }
                continue;
            }
            _save_c(c);
            chunk.next(1);
            continue;
          }
        default:
          _save_and_next();
      }
    }
    _save_and_next(); // 跳过分隔符
    var rawToken = _buff.toString();
    return rawToken.substring(1, rawToken.length - 1);
  }

  String readLongString(bool isString, int sep) {
    _save_and_next(); /* skip 2nd `[' */
    if (CharSequence.isNewLine(chunk.current)) /* string starts with a newline? */
      _incLineNumber();
    /* skip it */
    loop:
    for (;;) {
      switch (chunk.current) {
        case '':
          error(
              isString ? "unfinished long string" : "unfinished long comment");
          break;
        case ']':
          if (_skip_sep() == sep) {
            _save_and_next(); /* skip 2nd `]' */
            break loop;
          }
          break;

        case '\n':
        case '\r':
          _save_c(10); // write '\n'
          _incLineNumber();
          if (!isString) _buff.clear();
          break;
        default:
          if (isString)
            _save_and_next();
          else
            chunk.next(1);
      }
    }
    /* loop */
    if (isString) {
      var rawToken = _buff.toString();
      int trim_by = 2 + sep;
      return rawToken.substring(trim_by, rawToken.length - trim_by);
    } else
      return null;
  }

  int _skip_sep() {
    int count = 0;
    String s = chunk.current;
    // assert(s == '[' || s == ']') ;
    _save_and_next();
    while (chunk.current == '=') {
      _save_and_next();
      count++;
    }
    return (chunk.current == s) ? count : (-count) - 1;
  }

  String readNumeral() {
    String expo = "Ee";
    String first = chunk.current;
    _save_and_next();
    if (first == '0' && chunk.startsWith("xX"))  /* hexadecimal? */
      expo = "Pp";

    for (;;) {
      if (chunk.startsWith(expo))  /* exponent part? */
        chunk.startsWith("-+");  /* optional exponent sign */
      if (CharSequence.isxDigit(chunk.current) || chunk.current == '.')
        _save_and_next();
      else break;
    }
    return _buff.toString();
  }

  int _line() {
    return cachedNextToken != null ? lineBackup : line;
  }

  error(String msg) {
    throw Exception("$chunkName:${_line()}: $msg");
  }
}
