class Cidade {
  final int id;
  final String nome;
  final String? estado;
  final String? pais;
  final double latitude;
  final double longitude;

  const Cidade({
    required this.id,
    required this.nome,
    this.estado,
    this.pais,
    required this.latitude,
    required this.longitude,
  });

  factory Cidade.fromJson(Map<String, dynamic> json) {
    return Cidade(
      id: json['id'] as int,
      nome: json['name'] as String,
      estado: json['admin1'] as String?,
      pais: json['country'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  String get descricaoCompleta {
    final partes = [
      nome,
      if (estado != null && estado!.isNotEmpty) estado,
      if (pais != null && pais!.isNotEmpty) pais,
    ];
    return partes.join(' - ');
  }
}