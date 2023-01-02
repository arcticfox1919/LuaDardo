
import 'package:lua_dardo/src/api/lua_state.dart';
import 'package:lua_dardo/src/api/lua_type.dart';

extension LuaStateAccessor on LuaState {

  String? getGlobalStringValue(String name) {
    return (_globalToTop(name) == LuaType.luaString) ? toString2(getTop()) : null;
  }

  double? getGlobalDoubleValue(String name) {
    return (_globalToTop(name) == LuaType.luaNumber) ? toNumber(getTop()) : null;
  }

  int? getGlobalIntValue(String name) {
    return (_globalToTop(name) == LuaType.luaNumber) ? toInteger(getTop()) : null;
  }

  bool? getGlobalBoolValue(String name) {
    return (_globalToTop(name) == LuaType.luaBoolean) ? toBoolean(getTop()) : null;
  }

  LuaType _globalToTop(String name) => getGlobal(name);

}
