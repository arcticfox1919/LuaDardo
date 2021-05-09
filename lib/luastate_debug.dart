import 'lua.dart';

_print(int i,LuaType type,[String value]){
  var msg = "index:$i -> $type";
  if(value != null) msg += " value:$value";
  print(msg);
}

extension LuaStateDebug on LuaState {
  void printStack() {
    print(">------  stack  top  ------<");
    var len = this.getTop();
    for (int i = len; i >= 1; i--) {
      LuaType t = this.type(i);
      switch (this.type(i)) {
        case LuaType.luaNone:
          _print(i,t);
          break;

        case LuaType.luaNil:
          _print(i,t);
          break;

        case LuaType.luaNil:
          _print(i,t,"${this.toBoolean(i) ? "true" : "false"}");
          break;

        case LuaType.luaLightUserdata:
          _print(i, t);
          break;

        case LuaType.luaNumber:
          if (this.isInteger(i)) {
            _print(i,t,"(integer)${this.toInteger(i)}");
          } else if (this.isNumber(i)) {
            _print(i,t,"${this.toNumber(i)}");
          }
          break;

        case LuaType.luaString:
          _print(i,t,"${this.toStr(i)}");
          break;

        case LuaType.luaTable:
          _print(i,t);
          break;

        case LuaType.luaFunction:
          _print(i,t);
          break;

        case LuaType.luaUserdata:
          _print(i,t);
          break;

        case LuaType.luaThread:
          _print(i,t);
          break;
        default:
          _print(i,t,"${this.typeName(t)}");
          break;
      }
    }
    print(">------ stack bottom ------<");
  }
}