import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cidade.dart';
import '../models/previsao.dart';

class ClimaService {
  static Future<List<Cidade>> buscarCidades(String nome) async {
    final query = Uri.encodeComponent(nome.trim());
    final url = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search?name=$query&count=10&language=pt&format=json',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Erro ${response.statusCode} ao buscar cidades');
    }

    final dados = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final resultados = dados['results'] as List<dynamic>?;

    if (resultados == null || resultados.isEmpty) {
      return [];
    }

    return resultados
        .map((item) => Cidade.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<PrevisaoTempo> buscarPrevisao(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,precipitation,rain,wind_speed_10m'
      '&hourly=temperature_2m,precipitation_probability,precipitation,rain'
      '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max'
      '&timezone=America/Sao_Paulo',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Erro ${response.statusCode} ao buscar previsão');
    }

    final dados = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return PrevisaoTempo.fromJson(dados);
  }
}