import 'opcodes.dart';

class Instruction {

   static final int maxArg_bx = (1 << 18) - 1;   // 2^18-1 = 262143
   static final int maxArg_sbx = maxArg_bx >> 1; // 262143/2 = 131071


   /*
   31       22       13       5    0
    +-------+^------+-^-----+-^-----
    |b=9bits |c=9bits |a=8bits|op=6|
    +-------+^------+-^-----+-^-----
    |    bx=18bits    |a=8bits|op=6|
    +-------+^------+-^-----+-^-----
    |   sbx=18bits    |a=8bits|op=6|
    +-------+^------+-^-----+-^-----
    |    ax=26bits            |op=6|
    +-------+^------+-^-----+-^-----
   31      23      15       7      0
  */

   static OpCode getOpCode(int i) {
    return opCodes[i & 0x3F];
  }

   static int getA(int i) {
    return (i >> 6) & 0xFF;
  }

   static int getC(int i) {
    return (i >> 14) & 0x1FF;
  }

   static int getB(int i) {
    return (i >> 23) & 0x1FF;
  }

   static int getBx(int i) {
    return i >> 14;
  }

   static int getSBx(int i) {
    return getBx(i) - maxArg_sbx;
  }

   static int getAx(int i) {
    return i >> 6;
  }
}