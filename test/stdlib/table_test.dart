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
    state.call(0, 0);
  }catch(e,s){
    print('$e\n$s');
    return false;
  }
  return true;
}

void main() {
  test('lua table standard library test', () {
    expect(testTable(), true);
  });
}
