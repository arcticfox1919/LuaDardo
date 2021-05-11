import 'lua_type.dart';

abstract class LuaAuxLib {

/* Error-report functions */
  int error2(String fmt, [List<Object> a]);

  int argError(int arg, String extraMsg);

/* Argument check functions */
  void checkStack2(int sz, String msg);

  void argCheck(bool cond, int arg, String extraMsg);

  void checkAny(int arg);

  void checkType(int arg, LuaType t);

  int checkInteger(int arg);

  double checkNumber(int arg);

  String checkString(int arg);

  int optInteger(int arg, int d);

  double optNumber(int arg, double d);

  String optString(int arg, String d);

/* Load functions */
  bool doFile(String filename);

  bool doString(String str);

  ThreadStatus loadFile(String filename);

  ThreadStatus loadFileX(String filename, String mode);

  ThreadStatus loadString(String s);

/* Other functions */
  String typeName2(int idx);

  String toString2(int idx);

  int len2(int idx);

  bool getSubTable(int idx, String fname);

  LuaType getMetatableAux(String tname);

  LuaType getMetafield(int obj, String e);

  bool callMeta(int obj, String e);

  void openLibs();

  int ref (int t);
  void unRef (int t, int ref);

  void requireF(String modname, DartFunction openf, bool glb);

  void newLib(Map<String, DartFunction> l);

  void newLibTable(Map<String, DartFunction> l);
  bool newMetatable(String tname);

  void setMetatableAux(String tname);
  void setFuncs(Map<String, DartFunction> l, int nup);
}
