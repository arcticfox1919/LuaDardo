import '../api/lua_state.dart';
import 'closure.dart';
import 'lua_state_impl.dart';
import 'lua_table.dart';
import 'upvalue_holder.dart';


class LuaStack {

  /// virtual stack
  final List<Object> slots =  List();
  /// call info
  LuaStateImpl state;
  Closure closure;
  List<Object> varargs;
  Map<int, UpvalueHolder> openuvs;
  /// Program Counter
  int pc = 0;
  /// linked list
  LuaStack prev;

  int top() {
    return slots.length;
  }

  void push(Object val) {
    if (slots.length > 10000) { // TODO
      throw StackOverflowError();
    }
    slots.add(val);
  }

  Object pop() {
    return slots.removeAt(slots.length - 1);
  }

  void pushN(List<Object> vals, int n) {
    int nVals = vals == null ? 0 : vals.length;
    if (n < 0) {
      n = nVals;
    }
    for (int i = 0; i < n; i++) {
      push(i < nVals ? vals[i] : null);
    }
  }

  List<Object> popN(int n) {
    List<Object> vals = List<Object>();
    for (int i = 0; i < n; i++) {
      vals.add(pop());
    }
    return vals.reversed.toList();
  }

  int absIndex(int idx) {
    return idx >= 0 || idx <= lua_registryindex
        ? idx : idx + slots.length + 1;
  }

  bool isValid(int idx) {
    if (idx < lua_registryindex) { /* upvalues */
      int uvIdx = lua_registryindex - idx - 1;
      return closure != null && uvIdx < closure.upvals.length;
    }

    if (idx == lua_registryindex) {
      return true;
    }
    int absIdx = absIndex(idx);
    return absIdx > 0 && absIdx <= slots.length;
  }

  Object get(int idx) {
    if (idx < lua_registryindex) { /* upvalues */
      int uvIdx = lua_registryindex - idx - 1;
      if (closure != null
          && closure.upvals.length > uvIdx
          && closure.upvals[uvIdx] != null) {
        return closure.upvals[uvIdx].get();
      } else {
        return null;
      }
    }

    if (idx == lua_registryindex) {
      return state.registry;
    }
    int absIdx = absIndex(idx);
    if (absIdx > 0 && absIdx <= slots.length) {
      return slots[absIdx - 1];
    } else {
      return null;
    }
  }

  void set(int idx, Object val) {
    if (idx < lua_registryindex) { /* upvalues */
      int uvIdx = lua_registryindex - idx - 1;
      if (closure != null
          && closure.upvals.length > uvIdx
          && closure.upvals[uvIdx] != null) {
        closure.upvals[uvIdx].set(val);
      }
      return;
    }

    if (idx == lua_registryindex) {
      state.registry = (val as LuaTable);
      return;
    }
    int absIdx = absIndex(idx);
    slots[absIdx - 1] = val;
  }

  void reverse(int from, int to) {
    var obj;
    for(;from < to;from++,to--){
      obj = slots[from];
      slots[from] = slots[to];
      slots[to] = obj;
    }
  }

}