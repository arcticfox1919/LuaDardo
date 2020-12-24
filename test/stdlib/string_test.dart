import 'package:libd/libd.dart';
import 'package:test/test.dart';


bool testString(){
  try{
    LuaState state = newState();
    state.openLibs();
    state.loadString('''
print(string.gsub("hello world", "(%w+)", "%1 %1"))
print(string.len("abc"))
print(string.byte("abcABC", 1, 6))
print(string.char(97, 98, 99))
print(string.upper("acde"))
print(string.find("8Abc%a23", "%a"))
print(string.find("8Abc%a23", "(%a)"))
print(string.find("8Abc%a23", "(%a)", 4))
print(string.find("8Abc%a23", "%a", 1, true))
print(string.find("8Abca23", "Ab"))
print(string.match("abc123ABC456", "ABC"))
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
    expect(testString(), true);
  });
}
