# libd
Lua interpreter by dart

Example:

```dart
import 'package:libd/libd.dart';


void main(List<String> arguments) {
  LuaState state = newState();
  state.openLibs();
  state.loadString('''
a=10
while( a < 20 ) do
   print("a value is", a)
   a = a+1
end
''');
  state.call(0, 0);
}
```
