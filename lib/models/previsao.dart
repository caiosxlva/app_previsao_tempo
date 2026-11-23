class PrevisaoDiaria {
  final String data;
  final double tempMax;
  final double tempMin;
  final double chuvaSoma;
  final int probChuvaMax;

  const PrevisaoDiaria({
    required this.data,
    required this.tempMax,
    required this.tempMin,
    required this.chuvaSoma,
    required this.probChuvaMax,
  });
}

class PrevisaoHoraria {
  final String hora;
  final double temperatura;
  final int probChuva;

  const PrevisaoHoraria({
    required this.hora,
    required this.temperatura,
    required this.probChuva,
  });
}

class PrevisaoTempo {
  final double temperaturaAtual;
  final int umidadeAtual;
  final double precipitacaoAtual;
  final double ventoAtual;
  final List<PrevisaoHoraria> proximasHoras;
  final List<PrevisaoDiaria> proximosDias;

  const PrevisaoTempo({
    required this.temperaturaAtual,
    required this.umidadeAtual,
    required this.precipitacaoAtual,
    required this.ventoAtual,
    required this.proximasHoras,
    required this.proximosDias,
  });

  factory PrevisaoTempo.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;

    final timesHourly = hourly['time'] as List<dynamic>;
    final tempsHourly = hourly['temperature_2m'] as List<dynamic>;
    final probsHourly = hourly['precipitation_probability'] as List<dynamic>;

    final listaHoras = <PrevisaoHoraria>[];
    final limiteHoras = timesHourly.length < 24 ? timesHourly.length : 24;
    for (int i = 0; i < limiteHoras; i++) {
      final rawTime = timesHourly[i] as String;
      final horaFormatada = rawTime.split('T').last;
      listaHoras.add(
        PrevisaoHoraria(
          hora: horaFormatada,
          temperatura: (tempsHourly[i] as num).toDouble(),
          probChuva: (probsHourly[i] as num?)?.toInt() ?? 0,
        ),
      );
    }

    final timesDaily = daily['time'] as List<dynamic>;
    final maxDaily = daily['temperature_2m_max'] as List<dynamic>;
    final minDaily = daily['temperature_2m_min'] as List<dynamic>;
    final sumDaily = daily['precipitation_sum'] as List<dynamic>;
    final probDaily = daily['precipitation_probability_max'] as List<dynamic>;

    final listaDias = <PrevisaoDiaria>[];
    for (int i = 0; i < timesDaily.length; i++) {
      final partesData = (timesDaily[i] as String).split('-');
      final dataBr = '${partesData[2]}/${partesData[1]}';
      listaDias.add(
        PrevisaoDiaria(
          data: dataBr,
          tempMax: (maxDaily[i] as num).toDouble(),
          tempMin: (minDaily[i] as num).toDouble(),
          chuvaSoma: (sumDaily[i] as num?)?.toDouble() ?? 0.0,
          probChuvaMax: (probDaily[i] as num?)?.toInt() ?? 0,
        ),
      );
    }

    return PrevisaoTempo(
      temperaturaAtual: (current['temperature_2m'] as num).toDouble(),
      umidadeAtual: (current['relative_humidity_2m'] as num).toInt(),
      precipitacaoAtual: (current['precipitation'] as num).toDouble(),
      ventoAtual: (current['wind_speed_10m'] as num).toDouble(),
      proximasHoras: listaHoras,
      proximosDias: listaDias,
    );
  }
}