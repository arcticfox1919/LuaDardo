

import 'lua_aux_lib.dart';
import 'lua_basic_api.dart';
import '../state/lua_state_impl.dart';


const lua_minstack = 20;
const lua_maxstack = 1000000;
const lua_registryindex = -lua_maxstack - 1000;
const lua_multret = -1;
const lua_ridx_globals = 2;

const lua_maxinteger = 1<<63 - 1;
const lua_mininteger = -1 << 63;

abstract class LuaState extends LuaBasicAPI implements LuaAuxLib{


  static LuaState newState(){
    return LuaStateImpl();
  }
}
