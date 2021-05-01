import 'src/state/lua_state_impl.dart';

import 'src/api/lua_state.dart';

export 'src/api/lua_state.dart';
export 'src/api/lua_basic_api.dart';
export 'src/api/lua_aux_lib.dart';
export 'src/api/lua_vm.dart';
export 'src/api/lua_type.dart';



LuaState newState(){
  return LuaStateImpl();
}