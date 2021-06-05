import 'package:lua_dardo/lua.dart';
import 'package:test/test.dart';


bool testOS(){
  try{
    LuaState state = LuaState.newState();
    state.openLibs();
    state.loadString(r'''
local start = os.clock()

local s = 0
for i = 1, 10000000 do
      s = s + i;
end

print('sec:'..(os.clock()-start)) 
''');
    state.pCall(0, 0, 1);
  }catch(e,s){
    print('$e\n$s');
    return false;
  }
  return true;
}

void main() {
  test('lua OS standard library test', () {
    expect(testOS(), true);
  });
}
