import '../../binchunk/binary_chunk.dart';
import '../ast/block.dart';
import '../ast/exp.dart';
import 'exp_processor.dart';
import 'fi2proto.dart';
import 'funcinfo.dart';

class CodeGen {

  static Prototype genProto(Block chunk) {
    FuncDefExp fd = FuncDefExp(
      isVararg: true,
      block: chunk,
      parList: List.empty()
    );
    fd.lastLine = chunk.lastLine;

    FuncInfo fi = FuncInfo(null, fd);
    fi.addLocVar("_ENV", 0);
    ExpProcessor.processFuncDefExp(fi, fd, 0);
    return Fi2Proto.toProto(fi.subFuncs[0]);
  }

}