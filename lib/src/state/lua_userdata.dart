
class Userdata<T>{

  final List<T> _data = List(1);

  get data => _data.first;

  set data(T data)=> _data.first = data;
}