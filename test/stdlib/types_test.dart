
import 'package:lua_dardo/lua.dart';
import 'package:test/test.dart';

import '../utils/test_utils.dart';

bool testTypeInference(String value, String type) {
  return TestUtils.performLuaCode('''
varType = type($value);
''',
      (state) => (state.getGlobalStringValue("varType") == type));
}

bool testTypeChanging() {
  return TestUtils.performLuaCode('''
nilType = type(a)   --> (`a' is not initialized)

a = 10
numberType = type(a)

a = "a string!!"
stringType = type(a)

a = print
functionType = type(a)
''',
     (state) {
        return state.getGlobalStringValue("nilType") == "nil"
            && state.getGlobalStringValue("numberType") == "number"
            && state.getGlobalStringValue("stringType") == "string"
            && state.getGlobalStringValue("functionType") == "function";
     }
  );


}

void main() {
  /// https://www.lua.org/pil/2.html
  test('lua String type inference test', () => expect(testTypeInference('\"Hello World \"', "string"), true));
  test('lua Number type inference test', () => expect(testTypeInference('10.4*3', "number"), true));
  test('lua Function type test', () => expect(testTypeInference('print', "function"), true));
  test('lua type() type inference test', () => expect(testTypeInference('type', "function"), true));
  test('lua boolean type inference test', () => expect(testTypeInference('true', "boolean"), true));
  test('lua nil type inference test', () => expect(testTypeInference('nil', "nil"), true));
  test('lua type() result type inference test', () => expect(testTypeInference('type(X)', "string"), true));
  test('lua variable type changing test', () => expect(testTypeChanging(), true));
}
