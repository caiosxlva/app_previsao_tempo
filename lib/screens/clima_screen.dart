import 'package:flutter/material.dart';
import '../models/cidade.dart';
import '../models/previsao.dart';
import '../services/clima_service.dart';

class ClimaScreen extends StatefulWidget {
  const ClimaScreen({super.key});

  @override
  State<ClimaScreen> createState() => _ClimaScreenState();
}

class _ClimaScreenState extends State<ClimaScreen> {
  final _buscaController = TextEditingController(text: 'São Sebastião do Paraíso');

  List<Cidade> _cidadesEncontradas = [];
  bool _buscandoCidades = false;
  String? _erroBusca;

  Cidade? _cidadeSelecionada;
  Future<PrevisaoTempo>? _futurePrevisao;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pesquisarCidade();
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _pesquisarCidade() async {
    final termo = _buscaController.text.trim();
    if (termo.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _buscandoCidades = true;
      _erroBusca = null;
      _cidadesEncontradas = [];
    });

    try {
      final lista = await ClimaService.buscarCidades(termo);
      if (!mounted) return;

      setState(() {
        _cidadesEncontradas = lista;
        _buscandoCidades = false;
        if (lista.isEmpty) {
          _erroBusca = 'Nenhuma cidade encontrada para "$termo".';
        } else if (lista.length == 1) {
          _selecionarCidade(lista.first);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _buscandoCidades = false;
        _erroBusca = 'Falha ao buscar cidade: $e';
      });
    }
  }

  void _selecionarCidade(Cidade cidade) {
    setState(() {
      _cidadeSelecionada = cidade;
      _cidadesEncontradas = [];
      _futurePrevisao = ClimaService.buscarPrevisao(
        cidade.latitude,
        cidade.longitude,
      );
    });
  }

  void _recarregarPrevisao() {
    if (_cidadeSelecionada == null) return;
    setState(() {
      _futurePrevisao = ClimaService.buscarPrevisao(
        _cidadeSelecionada!.latitude,
        _cidadeSelecionada!.longitude,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previsão do Tempo'),
        actions: [
          if (_cidadeSelecionada != null)
            IconButton(
              onPressed: _recarregarPrevisao,
              icon: const Icon(Icons.refresh),
              tooltip: 'Recarregar',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buscaController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da cidade',
                      hintText: 'Ex: São Sebastião do Paraíso',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _pesquisarCidade(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _buscandoCidades ? null : _pesquisarCidade,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_buscandoCidades)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (_erroBusca != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _erroBusca!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ),

            if (_cidadesEncontradas.isNotEmpty)
              Expanded(
                child: Card(
                  child: ListView.separated(
                    itemCount: _cidadesEncontradas.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cidade = _cidadesEncontradas[index];
                      return ListTile(
                        leading: const Icon(Icons.place),
                        title: Text(cidade.nome),
                        subtitle: Text('${cidade.estado ?? ''} - ${cidade.pais ?? ''}'),
                        onTap: () => _selecionarCidade(cidade),
                      );
                    },
                  ),
                ),
              ),

            if (_cidadesEncontradas.isEmpty && _futurePrevisao != null)
              Expanded(
                child: FutureBuilder<PrevisaoTempo>(
                  future: _futurePrevisao,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Erro: ${snapshot.error}',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _recarregarPrevisao,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final clima = snapshot.data;
                    if (clima == null) {
                      return const Center(child: Text('Nenhum dado encontrado.'));
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Text(
                                    _cidadeSelecionada!.descricaoCompleta,
                                    style: Theme.of(context).textTheme.titleMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${clima.temperaturaAtual.toStringAsFixed(1)} °C',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _InfoItem(
                                        icone: Icons.water_drop,
                                        label: 'Umidade',
                                        valor: '${clima.umidadeAtual}%',
                                      ),
                                      _InfoItem(
                                        icone: Icons.umbrella,
                                        label: 'Chuva',
                                        valor: '${clima.precipitacaoAtual} mm',
                                      ),
                                      _InfoItem(
                                        icone: Icons.air,
                                        label: 'Vento',
                                        valor: '${clima.ventoAtual} km/h',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'Próximas Horas',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 110,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: clima.proximasHoras.length,
                              itemBuilder: (context, index) {
                                final h = clima.proximasHoras[index];
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          h.hora,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('${h.temperatura.toStringAsFixed(1)}°'),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.water_drop,
                                                size: 12, color: Colors.blue),
                                            Text(' ${h.probChuva}%',
                                                style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'Próximos Dias',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ...clima.proximosDias.map(
                            (dia) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.calendar_today),
                                title: Text('Dia ${dia.data}'),
                                subtitle: Text(
                                  'Chuva: ${dia.chuvaSoma} mm (${dia.probChuvaMax}%)',
                                ),
                                trailing: Text(
                                  '${dia.tempMin.toStringAsFixed(0)}° / ${dia.tempMax.toStringAsFixed(0)}°',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valor;

  const _InfoItem({
    required this.icone,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icone, size: 22),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}