class LuaMath {

  static double floorDiv(double a, double b) {
    return (a/b).floorToDouble();
  }

  static int iFloorDiv(int a, int b) {
    return (a/b).floor();
  }

  // a % b == a - ((a // b) * b)
  static double floorMod(double a, double b) {
    if (a > 0 && b == double.infinity
        || a < 0 && b == double.negativeInfinity) {
      return a;
    }
    if (a > 0 && b == double.negativeInfinity
        || a < 0 && b == double.infinity) {
      return b;
    }
    return a - (a/b).floorToDouble() * b;
  }

  static int shiftLeft(int a, int n) {
    return n >= 0 ? a << n : a.logicalRShift(-n);
  }

  static int shiftRight(int a, int n) {
    return n >= 0 ? a.logicalRShift(n) : a << -n;
  }

  static int iFloorMod(int x,int y){
    return (x - (x / y).floor() * y);
  }

  /// dart中int为64位整型，左移运算结果与32位整型不一致
  /// 因此左移完成后需舍弃高32位
  static int toInt32(int val){
    return val & 0xffffffff;
  }

}

extension  LogicalRightShift on  int{

  int logicalRShift(int size){
    return (this >> size) & 0x0FFFFFFFFFFFFFFF;
  }
}