class FriendlyError implements Exception {
  final String message;
  final bool unauthorized;
  const FriendlyError(this.message, {this.unauthorized = false});
  @override
  String toString() => message;
}
