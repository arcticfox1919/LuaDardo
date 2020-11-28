import '../binchunk/binary_chunk.dart';
import 'ast/block.dart';
import 'codegen/code_gen.dart';
import 'parser/parser.dart';

class Compiler {

  static Prototype compile(String chunk, String chunkName) {
    Block ast = Parser.parse(chunk, chunkName);
    Prototype proto = CodeGen.genProto(ast);
    _setSource(proto, chunkName);
    return proto;
  }

  static void _setSource(Prototype proto, String chunkName) {
    proto.source = chunkName;
    for (Prototype subProto in proto.protos) {
      _setSource(subProto, chunkName);
    }
  }

}