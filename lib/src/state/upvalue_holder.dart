
import 'lua_stack.dart';

class UpvalueHolder {

  final int index;
  LuaStack stack;
  Object value;

  UpvalueHolder.value(this.value) :this.index = 0;

  UpvalueHolder(this.stack, this.index);

  Object get() {
    return stack != null ? stack.get(index + 1) : value;
  }

  void set(Object value) {
    if (stack != null) {
      stack.set(index + 1, value);
    } else {
      this.value = value;
    }
  }

  void migrate() {
    if (stack != null) {
      value = stack.get(index + 1);
      stack = null;
    }
  }

}