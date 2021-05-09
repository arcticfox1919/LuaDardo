class CharSequence {
  final String _str;
  int _pos;

  CharSequence(this._str) : this._pos = 0;

  @override
  String toString() {
    return _str;
  }

  String nextChar() {
    return _str[_pos++];
  }

  // 跳过n个字符
  void next(int n) {
    _pos += n;
  }

  bool startsWith(String prefix) {
    return _str.startsWith(prefix, _pos);
  }

  int indexOf(String s) {
    return _str.indexOf(s, _pos) - _pos;
  }

  String substring(int beginIndex, int endIndex) {
    return _str.substring(beginIndex + _pos, endIndex + _pos);
  }

  int get length => _str.length - _pos;

  String charAt(int index) {
    int i = index + _pos;
    if(i>=_str.length) return '';
    return _str[i];
  }

  get current {
    return charAt(0);
  }

  // 是否是空白字符
  static bool isWhiteSpace(String c) {
    switch (c.codeUnitAt(0)) {
      case 9:  // '\t'
      case 10: // '\n'
      case 11: // '\v'
      case 12: // '\f'
      case 13: // '\r'
      case 32: // ' '
        return true;
    }
    return false;
  }

  static bool isNewLine(String c) {
    return c == '\r' || c == '\n';
  }

  static bool isDigit(String c) {
    var code = c.codeUnitAt(0);
    // '0'~'9'
    return code >= 48 && code <= 57;
  }

  static bool isxDigit(String s) {
    return int.tryParse(s, radix: 16) != null;
  }

  static bool isLetter(String c) {
    var code = c.codeUnitAt(0);
    // a~z and A~Z
    return code >= 97 && code <= 122 || code >= 65 && code <= 90;
  }

  static bool isalnum(String c) {
    var code = c.codeUnitAt(0);
    // '0'~'9' or a~z or A~Z
    return code >= 48 && code <= 57 ||
        code >= 97 && code <= 122 ||
        code >= 65 && code <= 90;
  }

  static int count(String src,String ch){
    if(src == null) return -1;
    if(src.isEmpty) return 0;

    var sum=0;
    var len = src.length;
    for(var i = 0; i<len; i++){
      if(src[i] == ch) sum++;
    }
    return sum;
  }
}
