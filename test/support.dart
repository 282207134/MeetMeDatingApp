import 'package:meetme/src/store.dart';

class MemoryStorage implements LocalStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}
