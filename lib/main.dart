
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MeuApp());
}

class Tarefa {
  String titulo;
  bool concluida;

  Tarefa({required this.titulo, this.concluida = false});

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'concluida': concluida,
      };

  factory Tarefa.fromJson(Map<String, dynamic> json) {
    return Tarefa(
      titulo: json['titulo'] as String,
      concluida: json['concluida'] as bool? ?? false,
    );
  }
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Minhas Tarefas',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7659E8),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF10111F),
      ),
      home: const TelaTarefas(),
    );
  }
}

class TelaTarefas extends StatefulWidget {
  const TelaTarefas({super.key});

  @override
  State<TelaTarefas> createState() => _TelaTarefasState();
}

class _TelaTarefasState extends State<TelaTarefas> {
  final TextEditingController controller = TextEditingController();
  final List<Tarefa> tarefas = [];
  final String chave = 'minhas_tarefas';
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarTarefas();
  }

  Future<void> carregarTarefas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dados = prefs.getString(chave);

      if (dados != null) {
        final lista = jsonDecode(dados) as List<dynamic>;

        if (!mounted) return;
        setState(() {
          tarefas.clear();
          tarefas.addAll(
            lista.map((item) =>
                Tarefa.fromJson(Map<String, dynamic>.from(item as Map))),
          );
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar tarefas: $e');
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  Future<void> salvarTarefas() async {
    final prefs = await SharedPreferences.getInstance();
    final dados = jsonEncode(
      tarefas.map((tarefa) => tarefa.toJson()).toList(),
    );
    await prefs.setString(chave, dados);
  }

  Future<void> adicionarTarefa() async {
    final titulo = controller.text.trim();

    if (titulo.isEmpty) return;

    setState(() {
      tarefas.insert(0, Tarefa(titulo: titulo));
      controller.clear();
    });

    await salvarTarefas();
  }

  Future<void> alternarConclusao(int index, bool? valor) async {
    setState(() {
      tarefas[index].concluida = valor ?? false;
    });

    await salvarTarefas();
  }

  Future<void> excluirTarefa(int index) async {
    setState(() {
      tarefas.removeAt(index);
    });

    await salvarTarefas();
  }

  Future<void> editarTarefa(int index) async {
    final editor = TextEditingController(text: tarefas[index].titulo);

    final novoTitulo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar tarefa'),
        content: TextField(
          controller: editor,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(
            labelText: 'Título da tarefa',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, editor.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    editor.dispose();

    if (novoTitulo == null || novoTitulo.isEmpty || !mounted) return;

    setState(() {
      tarefas[index].titulo = novoTitulo;
    });

    await salvarTarefas();
  }

  Future<void> limparConcluidas() async {
    setState(() {
      tarefas.removeWhere((tarefa) => tarefa.concluida);
    });

    await salvarTarefas();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final concluidas = tarefas.where((t) => t.concluida).length;
    final pendentes = tarefas.length - concluidas;
    final progresso =
        tarefas.isEmpty ? 0.0 : concluidas / tarefas.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'TaskFlow',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Limpar concluídas',
            onPressed: concluidas == 0 ? null : limparConcluidas,
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Organize seu dia ✨',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pequenos passos, grandes conquistas.',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF7659E8),
                            Color(0xFF4932A3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seu progresso',
                            style: TextStyle(fontSize: 17),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$concluidas de ${tarefas.length} tarefas concluídas',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: progresso,
                            minHeight: 9,
                            borderRadius: BorderRadius.circular(20),
                            backgroundColor: Colors.white24,
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$pendentes pendentes • $concluidas concluídas',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            maxLength: 100,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => adicionarTarefa(),
                            decoration: InputDecoration(
                              hintText: 'Adicionar nova tarefa...',
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFF202235),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 55,
                          width: 55,
                          child: FilledButton(
                            onPressed: adicionarTarefa,
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: const Color(0xFF7659E8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Icon(Icons.add, size: 28),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    Text(
                      'Minhas tarefas (${tarefas.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: tarefas.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.task_alt,
                                    size: 75,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Nenhuma tarefa por enquanto!',
                                    style: TextStyle(fontSize: 17),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Adicione sua primeira tarefa acima.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: tarefas.length,
                              itemBuilder: (context, index) {
                                final tarefa = tarefas[index];

                                return Card(
                                  color: const Color(0xFF202235),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    leading: Checkbox(
                                      value: tarefa.concluida,
                                      activeColor: const Color(0xFF7659E8),
                                      onChanged: (valor) =>
                                          alternarConclusao(index, valor),
                                    ),
                                    title: Text(
                                      tarefa.titulo,
                                      style: TextStyle(
                                        decoration: tarefa.concluida
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        color: tarefa.concluida
                                            ? Colors.grey
                                            : Colors.white,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Editar',
                                          onPressed: () => editarTarefa(index),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Excluir',
                                          onPressed: () => excluirTarefa(index),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
