import 'lua_state.dart';

abstract class LuaVM extends LuaState {
  int getPC();

  void addPC(int n);

  int fetch();

  void getConst(int idx);

  void getRK(int rk);

  int registerCount();

  void loadVararg(int n);

  void loadProto(int idx);

  void closeUpvalues(int a);
}
