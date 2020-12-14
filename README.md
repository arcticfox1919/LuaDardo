# libd

**[Lua5.3](http://www.lua.org/manual/5.3/) interpreter by [Dart](https://github.com/dart-lang/sdk)**

Example:

```yaml
dependencies:
  libd:
    git: https://github.com/arcticfox1919/libd.git
```

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

**For use in flutter, see [here](https://github.com/arcticfox1919/libd_flutter).**
