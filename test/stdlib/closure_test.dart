
import 'package:lua_dardo/lua.dart';
import 'package:test/test.dart';

import '../utils/test_utils.dart';

bool testTypeChanging() {
  return TestUtils.performLuaCode('''
function newCounter ()
  local i = 0
  return function ()   -- anonymous function
           i = i + 1
           return i
         end
end

c1 = newCounter()
print(c1())  --> 1
print(c1())  --> 2
clResult = c1();
''',
          (state) {
        return state.getGlobalIntValue("clResult") == 3;
      }
  );
}

bool testClosureOverride() {
  return TestUtils.performLuaCode('''
do
  local oldSin = math.sin
  local k = math.pi/180
  math.sin = function (x)
    return oldSin(x*k)
  end
  sinRes = math.sin(90);
end
''',
          (state) {
        double? result = state.getGlobalDoubleValue("sinRes");
        return result != null && (result - 1.0).abs() < 0.001;
      }
  );
}

void main() {
  // https://www.lua.org/pil/6.1.html
  test('lua Closures test', () => expect(testTypeChanging(), true));
  test('lua Closure override test', () => expect(testClosureOverride(), true));
}
