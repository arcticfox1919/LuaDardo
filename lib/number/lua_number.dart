class LuaNumber {

  static bool isInteger(double f) {
    return f == f.toInt();
  }

  // TODO
  static int parseInteger(String str) {
    try {
      return int.parse(str);
    } catch (e) {
      return null;
    }
  }

  // TODO
  static double parseFloat(String str) {
    try {
      return double.parse(str);
    } catch (e) {
      return null;
    }
  }

}
