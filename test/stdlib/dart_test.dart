
import 'package:lua_dardo/lua.dart';
import 'package:test/test.dart';

bool testDartFunctions() {
  try {
    bool changed = false;
    LuaState state = LuaState.newState();
    state.openLibs();
    state.pushDartFunction((ls) {
      changed = true;
      return 0;
    });
    state.setGlobal('test');
    state.loadString('test()');
    state.pCall(0, 0, 1);

    return changed;
  } catch(e,s){
    print('$e\n$s');
  }

  return false;
}

void main() {
  test('lua Dart function calling test', () => expect(testDartFunctions(), true));
}
