class Middleware {
  List<Function> callbacks;
  Map<dynamic, dynamic>? locals;
  String? method;
  String? path;
  RegExp? regExp;

  Middleware(this.callbacks, this.locals);
  Middleware.listener(
      this.callbacks, this.locals, this.method, this.path, this.regExp);
}
