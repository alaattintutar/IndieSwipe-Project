import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_service.dart';
import 'game_model.dart';

final gamesProvider = FutureProvider<List<Game>>((ref) async {
  final api = ApiService();
  final response = await api.get('/games/daily');
  final List data = response.data['games'];
  return data.map((json) => Game.fromJson(json)).toList();
});