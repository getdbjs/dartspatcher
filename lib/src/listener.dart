class Listener {
  String path;
  Function callback;
  RegExp regExp;
  Map<dynamic, dynamic> locals;

  Listener(this.path, this.callback, this.regExp, this.locals);
}
