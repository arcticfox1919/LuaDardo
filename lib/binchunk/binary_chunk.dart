import 'dart:convert';
import 'dart:typed_data';

import 'buffer.dart';

const luaSignature = [0x1b,0x4c,0x75,0x61];
const luacVersion = 0x53;
const luacFormat = 0;
const luacData = [0x19, 0x93, 0x0d, 0x0a, 0x1a, 0x0a];
const cintSize = 4;
const csizetSize = 8;
const instructionSize = 4;
const luaIntegerSize = 8;
const luaNumberSize = 8;
const luacInt = 0x5678;
const luacNum = 370.5;

/// 常量类型
const tag_nil = 0x00;
const tag_boolean = 0x01;
const tag_number = 0x03;
const tag_integer = 0x13;
const tag_short_str = 0x04;
const tag_long_str = 0x14;

class _Header {
  /// 签名。二进制文件的魔数:0x1B4C7561
  Uint8List signature = Uint8List(4);

  /// 版本号。值为大版本号乘以16加小版本号
  int version;

  /// 格式号
  int format;

  /// 前两个字节是0x1993，是Lua 1.0发布的年份；
  /// 后四个字节依次是回车符（0x0D）、换行符（0x0A）、
  /// 替换符（0x1A）和另一个换行符
  Uint8List luacData = Uint8List(6);

  /// 分别记录cint、size_t、Lua虚拟机指令、
  /// Lua整数和Lua浮点数5种数据类型在二进制的字节长度
  int cintSize;
  int sizetSize;
  int instructionSize;
  int luaIntegerSize;
  int luaNumberSize;

  /// 存放Lua整数值0x5678
  int luacInt;

  /// 存放Lua浮点数370.5
  double luacNum;
}

class Prototype {
  /// 源文件名
  String source;

  /// 起始行号
  int lineDefined;

  /// 终止行号
  int lastLineDefined;

  /// 函数固定参数个数
  int numParams;

  /// 是否有变长参数
  int isVararg;

  /// 寄存器数量
  int maxStackSize;

  /// 指令表
  Uint32List code;

  /// 常量表
  List<Object> constants;

  /// Upvalue表
  List<Upvalue> upvalues;

  /// 子函数原型表
  List<Prototype> protos;

  /// 行号表
  Uint32List lineInfo;

  /// 局部变量表
  List<LocVar> locVars;

  /// Upvalue名字列表
  List<String> upvalueNames;

  Prototype();

  Prototype.from(ByteDataReader data, String parentSource) {
    source = BinaryChunk.getLuaString(data);
    if (source.isEmpty) {
      source = parentSource;
    }

    lineDefined = data.readUint32();
    lastLineDefined = data.readUint32();
    numParams = data.readUint8();
    isVararg = data.readUint8();
    maxStackSize = data.readUint8();
    var len = data.readUint32();

    code = Uint32List(len);
    for(var i = 0;i<len;i++){
      code[i] = data.readUint32();
    }

    len = data.readUint32();
    constants = List(len);
    for (var i = 0; i < len; i++) {
      var kind = data.readUint8();
      switch (kind) {
        case tag_nil:
          constants[i] = null;
          break;
        case tag_boolean:
          constants[i] = data.readUint8() != 0;
          break;
        case tag_integer:
          constants[i] = data.readUint64();
          break;
        case tag_number:
          constants[i] = data.readFloat64();
          break;
        case tag_short_str:
        case tag_long_str:
          constants[i] = BinaryChunk.getLuaString(data);
          break;
        default:
          throw Exception("corrupted!");
      }
    }

    len = data.readUint32();
    upvalues = List(len);
    for (var i = 0; i < len; i++) {
      upvalues[i] = Upvalue.from(data);
    }

    len = data.readUint32();
    protos = List(len);
    for (var i = 0; i < len; i++) {
      protos[i] = Prototype.from(data, parentSource);
    }

    len = data.readUint32();
    lineInfo = Uint32List(len);
    for(var i = 0;i<len;i++){
      lineInfo[i] = data.readUint32();
    }

    len = data.readUint32();
    locVars = List(len);
    for (var i = 0; i < len; i++) {
      locVars[i] = LocVar.from(data);
    }

    len = data.readUint32();

    upvalueNames = List(len);
    for (var i = 0; i < len; i++) {
      upvalueNames[i] = BinaryChunk.getLuaString(data);
    }
  }
}

class Upvalue {
  int instack;
  int idx;

  Upvalue();

  Upvalue.from(ByteDataReader blob) {
    instack = blob.readUint8();
    idx = blob.readUint8();
  }
}

class LocVar {
  String varName;
  int startPC;
  int endPC;

  LocVar();
  LocVar.from(ByteDataReader blob){
    varName = BinaryChunk.getLuaString(blob);
    startPC = blob.readUint32();
    endPC = blob.readUint32();
  }
}

class BinaryChunk {
  _Header header;

  /// 解析二进制
  static Prototype undump(Uint8List data) {
    var byteReader = ByteDataReader(endian:Endian.little)
      ..add(data);
    _checkHead(byteReader);
    byteReader.readUint8();// 跳过 size_upvalues
    return Prototype.from(byteReader, "");
  }

  static void _checkHead(ByteDataReader blob) {
    var magicNum = blob.read(4);

    for (var i = 0; i < 4; i++) {
      if (luaSignature[i] != magicNum[i]) {
        throw new Exception("not a precompiled chunk!");
      }
    }

    if (luacVersion != blob.readUint8()) {
      throw new Exception("version mismatch!");
    }

    if (luacFormat != blob.readUint8()) {
      throw new Exception("format mismatch!");
    }

    var data = blob.read(6);
    for (var i = 0; i < 6; i++) {
      if (data[i] != luacData[i]) {
        throw new Exception("LUAC_DATA corrupted!");
      }
    }

    if (cintSize != blob.readUint8()) {
      throw new Exception("int size mismatch!");
    }

    if (csizetSize != blob.readUint8()) {
      throw new Exception("size_t size mismatch!");
    }

    if (instructionSize != blob.readUint8()) {
      throw new Exception("instruction size mismatch!");
    }

    if (luaIntegerSize != blob.readUint8()) {
      throw new Exception("lua_Integer size mismatch!");
    }

    if (luaNumberSize != blob.readUint8()) {
      throw new Exception("lua_Number size mismatch!");
    }

    if (luacInt != blob.readUint64()) {
      throw new Exception("endianness mismatch!");
    }

    if (luacNum != blob.readFloat64()) {
      throw new Exception("float format mismatch!");
    }
  }

  static String getLuaString(ByteDataReader blob) {
    int size = blob.readUint8();
    if (size == 0) {
      return "";
    }
    if (size == 0xFF) {
      size = blob.readUint64(); // size_t
    }

    var strBytes = blob.read(size - 1);
    return utf8.decode(strBytes);
  }

  static bool isBinaryChunk(Uint8List data) {
    if (data == null || data.length < 4) {
      return false;
    }
    for (int i = 0; i < 4; i++) {
      if (data[i] != luaSignature[i]) {
        return false;
      }
    }
    return true;
  }
}
