import 'dart:async';

typedef Callback = Object Function();

void main() async {
  print("before check");
  const cb = futureInt;
  await checkInt(cb);

  print("after check");
}

Future<void> checkInt(dynamic c) async {
  c.call(1);
}

FutureOr<int> futureInt(int i) async {
  if (i < 3) {
    print("$i");
    final res = futureInt(i++);
    if (res is Future) {
      final r = await res;
      print("after res await:$r");
      return r;
    } else {
      throw Error();
    }
  }
  return 0;
}
