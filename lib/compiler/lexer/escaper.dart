
import 'char_sequence.dart';
import 'lexer.dart';

class Escaper{
   static final reDecEscapeSeq = RegExp("^\\\\[0-9]{1,3}");
   static final reHexEscapeSeq = RegExp("^\\\\x[0-9a-fA-F]{2}");
   static final reUnicodeEscapeSeq = RegExp("^\\\\u\\{[0-9a-fA-F]+}");

   CharSequence rawStr;
   Lexer lexer;
   StringBuffer buf = StringBuffer();

  Escaper(String rawStr, this.lexer): this.rawStr = CharSequence(rawStr);

  String escape() {
    while (rawStr.length > 0) {
      if (rawStr.charAt(0) != '\\') {
        buf.write(rawStr.nextChar());
        continue;
      }

      if (rawStr.length == 1) {
        return lexer.error("unfinished string");
      }

      switch (rawStr.charAt(1)) {
        case 'a':  buf.writeCharCode(0x07); rawStr.next(2); continue; // Bell
        case 'v':  buf.writeCharCode(0x0B); rawStr.next(2); continue; // Vertical tab
        case 'b':  buf.write('\b'); rawStr.next(2); continue;
        case 'f':  buf.write('\f'); rawStr.next(2); continue;
        case 'n':  buf.write('\n'); rawStr.next(2); continue;
        case 'r':  buf.write('\r'); rawStr.next(2); continue;
        case 't':  buf.write('\t'); rawStr.next(2); continue;
        case '"':  buf.write('"');  rawStr.next(2); continue;
        case '\'': buf.write('\''); rawStr.next(2); continue;
        case '\\': buf.write('\\'); rawStr.next(2); continue;
        case '\n': buf.write('\n'); rawStr.next(2); continue;
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9': escapeDecSeq();     continue; // \ddd
        case 'x': escapeHexSeq();     continue; // \xXX
        case 'u': escapeUnicodeSeq(); continue; // \ u{XXX}
        case 'z':
          rawStr.next(2);
          skipWhitespaces();
          continue;
      }
      reportInvalidEscapeSeq();
    }

    return buf.toString();
  }

   void reportInvalidEscapeSeq() {
    lexer.error("invalid escape sequence near '\\${rawStr.charAt(1)}'");
  }

  // \ddd
   void escapeDecSeq() {
    // String seq = rawStr.find(reDecEscapeSeq);
    // if (seq == null) {
    //   reportInvalidEscapeSeq();
    // }
    //
    // try {
    //   int d = int.parse(seq.substring(1));
    //   if (d <= 0xFF) {
    //     buf.writeCharCode(d);
    //     rawStr.next(seq.length);
    //     return;
    //   }
    // } catch (e) {}

    // lexer.error("decimal escape too large near '$seq'");
  }

  // \xXX
   void escapeHexSeq() {
    // String seq = rawStr.find(reHexEscapeSeq);
    // if (seq == null) {
    //   reportInvalidEscapeSeq();
    // }
    //
    // int d = int.parse(seq.substring(2), radix: 16);
    // buf.writeCharCode(d);
    // rawStr.next(seq.length);
  }

  // \u{XXX}
   void escapeUnicodeSeq() {
    // String seq = rawStr.find(reUnicodeEscapeSeq);
    // if (seq == null) {
    //   reportInvalidEscapeSeq();
    // }
    //
    // try {
    //   int d = int.parse(seq.substring(3, seq.length - 1), radix: 16);
    //   if (d <= 0x10FFFF) {
    //     buf.writeCharCode(d);
    //     rawStr.next(seq.length);
    //     return;
    //   }
    // } catch (e) {}

    // lexer.error("UTF-8 value too large near '$seq'");
  }

   void skipWhitespaces() {
    while (rawStr.length > 0
        && CharSequence.isWhiteSpace(rawStr.charAt(0))) {
      rawStr.next(1);
    }
  }
}