import '../api/lua_type.dart';
import '../binchunk/binary_chunk.dart';
import 'upvalue_holder.dart';

class Closure {

  final Prototype? proto;
  final DartFunction? dartFunc;
  final List<UpvalueHolder?> upvals;

  Closure(Prototype this.proto) :
        this.dartFunc = null,
        this.upvals = List<UpvalueHolder?>.filled(proto.upvalues.length,null);

  Closure.DartFunc(this.dartFunc, int nUpvals) :
        this.proto = null,
        this.upvals = List<UpvalueHolder?>.filled(nUpvals,null);

}