# LuaDardo

![logo](https://github.com/arcticfox1919/ImageHosting/blob/master/language_logo.png?raw=true)

------

A Lua virtual machine written in [Dart](https://github.com/dart-lang/sdk), which implements [Lua5.3](http://www.lua.org/manual/5.3/) version.

## Example:

```yaml
dependencies:
  lua_dardo: ^0.0.1
```

```dart
import 'package:lua_dardo/lua.dart';


void main(List<String> arguments) {
  LuaState state = newState();
  state.openLibs();
  state.loadString(r'''
a=10
while( a < 20 ) do
   print("a value is", a)
   a = a+1
end
''');
  state.call(0, 0);
}
```

**For use in flutter, see [here](https://github.com/arcticfox1919/flutter_lua_dardo).**
