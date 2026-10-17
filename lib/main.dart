import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/app.dart';
import 'src/store.dart';
import 'src/profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final store = await AppStore.load(PreferencesStorage());
  await recoverProfilePhoto(store);
  runApp(MeetMeApp(store: store));
}
