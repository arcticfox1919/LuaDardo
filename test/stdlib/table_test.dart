import 'package:lua_dardo/lua.dart';
import 'package:test/test.dart';


bool testTable(){
  try{
    LuaState state = LuaState.newState();
    state.openLibs();
    state.loadString(r'''
local arr = {"beta","alpha",}

table.insert(arr,1, "zeta")
table.insert(arr,2, "epsilon")
table.insert(arr,"delta")

print(table.concat(arr, ","))

table.remove(arr)

table.sort(arr)
print(table.concat(arr, ","))

local a1 = {"a","b","c","d"}
table.move(a1 ,1,#a1,4)
print(table.concat(a1, ",")) 
''');
    state.pCall(0, 0, 1);
  }catch(e,s){
    print('$e\n$s');
    return false;
  }
  return true;
}

bool testTableTraversing(){
  bool result = false;

  try{
    LuaState state = LuaState.newState();
    state.openLibs();
    state.loadString(r'''
local alphabet = {}
alphabet.a = 'alpha'
alphabet.b = 'beta'

--trigger keys initializastion
local val = next(alphabet, 'b')

alphabet.c = 'gamma'

result = false;
for k, v in pairs(alphabet) do
  if (k == 'c' and v == 'gamma')
  then
    result = true;
  end
end
''');
    state.pCall(0, 0, 1);
    LuaType resultType = state.getGlobal("result");
    if (resultType == LuaType.luaBoolean) {
      result = state.toBoolean(state.getTop());
    }
  } catch(e,s){
    print('$e\n$s');
  }

  return result;
}

void main() {
  //test('lua table standard library test', () {
  //  expect(testTable(), true);
  //});
  test('\nlua traversing table test', () {
    expect(testTableTraversing(), true);
  });
}
