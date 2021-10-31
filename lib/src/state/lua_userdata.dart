
class Userdata<T>{

  final List<T?> _data = List.filled(1,null);

  T? get data => _data.first;

  set data(T? data)=> _data.first = data;
}