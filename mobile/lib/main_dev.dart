import 'main.dart' as app;
import 'core/constants/app_config.dart';

void main() async {
  await app.bootstrap(AppFlavor.development);
}
