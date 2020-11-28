import 'dart:typed_data';

import 'lua_aux_lib.dart';
import 'lua_basic_api.dart';
import 'lua_type.dart';

const lua_minstack = 20;
const lua_maxstack = 1000000;
const lua_registryindex = -lua_maxstack - 1000;
const lua_multret = -1;
const lua_ridx_globals = 2;

abstract class LuaState extends LuaBasicAPI with LuaAuxLib{

}
