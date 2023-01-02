
import 'package:lua_dardo/lua.dart';

class TestUtils {

  TestUtils._internal();

  static bool performLuaCode(String luaCode, TestEvaluator evaluator) {
    try{
      LuaState state = LuaState.newState();
      state.openLibs();
      state.loadString(luaCode);
      state.pCall(0, 0, 1);

      return evaluator(state);
    } catch(e,s){
      print('$e\n$s');
    }
    return false;
  }

}

typedef bool TestEvaluator(LuaState state);
