import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/di/injection.dart';
import 'ai_service.dart';
import 'direct_client_ai_service.dart';

part 'ai_provider.g.dart';

@riverpod
AiService aiService(Ref ref) {
  // MVP offline và client-side sử dụng DirectClientAiService
  return DirectClientAiService(getIt<SharedPreferences>());
}
