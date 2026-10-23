import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lista de Tarefas',
      home: TelaTarefas(),
    );
  }
}

// ---------- Modelo ----------
class Tarefa {
  String titulo;
  bool concluida;

  Tarefa({required this.titulo, this.concluida = false});

  // Converte para Map (para salvar em JSON)
  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'concluida': concluida,
      };

  // Reconstrói a partir de Map (ao carregar)
  factory Tarefa.fromJson(Map<String, dynamic> json) => Tarefa(
        titulo: json['titulo'] as String,
        concluida: json['concluida'] as bool? ?? false,
      );
}

// ---------- Tela ----------
class TelaTarefas extends StatefulWidget {
  const TelaTarefas({super.key});

  @override
  State<TelaTarefas> createState() => _TelaTarefasState();
}

class _TelaTarefasState extends State<TelaTarefas> {
  static const String _chaveStorage = 'tarefas';

  final TextEditingController _controller = TextEditingController();
  final List<Tarefa> _tarefas = [];

  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------- Persistência ----------
  Future<void> _carregarTarefas() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dados = prefs.getString(_chaveStorage);
    if (dados != null && dados.isNotEmpty) {
      final List<dynamic> listaJson = jsonDecode(dados) as List<dynamic>;
      setState(() {
        _tarefas
          ..clear()
          ..addAll(
            listaJson.map((e) => Tarefa.fromJson(e as Map<String, dynamic>)),
          );
      });
    }
    setState(() {
      _carregando = false;
    });
  }

  Future<void> _salvarTarefas() async {
    final prefs = await SharedPreferences.getInstance();
    final String dados = jsonEncode(
      _tarefas.map((t) => t.toJson()).toList(),
    );
    await prefs.setString(_chaveStorage, dados);
  }

  // ---------- Ações ----------
  Future<void> _adicionarTarefa() async {
    final String texto = _controller.text.trim();
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o título da tarefa.')),
      );
      return;
    }
    setState(() {
      _tarefas.add(Tarefa(titulo: texto));
    });
    _controller.clear();
    await _salvarTarefas();
    if (!mounted) return;
    FocusScope.of(context).requestFocus(FocusNode());
  }

  Future<void> _alternarConclusao(int index) async {
    setState(() {
      _tarefas[index].concluida = !_tarefas[index].concluida;
    });
    await _salvarTarefas();
  }

  Future<void> _excluirTarefa(int index) async {
    // Desafio: confirmação antes de excluir
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir tarefa'),
        content: Text('Deseja excluir "${_tarefas[index].titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    setState(() {
      _tarefas.removeAt(index);
    });
    await _salvarTarefas();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final int pendentes = _tarefas.where((t) => !t.concluida).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Tarefas'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Total: ${_tarefas.length}  •  Pendentes: $pendentes',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Campo de entrada
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            labelText: 'Nova tarefa',
                            hintText: 'Ex.: Estudar Flutter',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _adicionarTarefa(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _adicionarTarefa,
                        icon: const Icon(Icons.add),
                        tooltip: 'Adicionar',
                      ),
                    ],
                  ),
                ),
                // Lista
                Expanded(
                  child: _tarefas.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma tarefa cadastrada.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _tarefas.length,
                          itemBuilder: (context, index) {
                            final Tarefa t = _tarefas[index];
                            return CheckboxListTile(
                              value: t.concluida,
                              onChanged: (_) => _alternarConclusao(index),
                              title: Text(
                                t.titulo,
                                style: TextStyle(
                                  decoration: t.concluida
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: t.concluida ? Colors.grey : null,
                                ),
                              ),
                              secondary: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                tooltip: 'Excluir',
                                onPressed: () => _excluirTarefa(index),
                              ),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}