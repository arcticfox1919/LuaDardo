import '../../binchunk/binary_chunk.dart';
import '../ast/block.dart';
import '../ast/exp.dart';
import 'exp_processor.dart';
import 'fi2proto.dart';
import 'funcinfo.dart';

class CodeGen {

  static Prototype genProto(Block chunk) {
    FuncDefExp fd = FuncDefExp();
    fd.lastLine = chunk.lastLine;
    fd.IsVararg = true;
    fd.block = chunk;

    FuncInfo fi = FuncInfo(null, fd);
    fi.addLocVar("_ENV", 0);
    ExpProcessor.processFuncDefExp(fi, fd, 0);
    return Fi2Proto.toProto(fi.subFuncs[0]);
  }

}