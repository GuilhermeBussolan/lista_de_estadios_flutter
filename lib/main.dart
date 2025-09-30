import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static const String rm = '552455';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Estádios',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: EstadioListPage(rm: rm),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Estadio {
  final String id;
  final String imagem;
  final String titulo;
  final String descricao;
  final int capacidade;

  Estadio({
    required this.id,
    required this.imagem,
    required this.titulo,
    required this.descricao,
    required this.capacidade,
  });

  factory Estadio.fromJson(Map<String, dynamic> json) {
    return Estadio(
      id: json['id'].toString(),
      imagem: json['imagem'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      capacidade: json['capacidade'],
    );
  }
}

class EstadioListPage extends StatefulWidget {
  final String rm;
  EstadioListPage({required this.rm});

  @override
  _EstadioListPageState createState() => _EstadioListPageState();
}

class _EstadioListPageState extends State<EstadioListPage> {
  List<Estadio> estadios = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchEstadios();
  }

  Future<void> fetchEstadios() async {
    setState(() => loading = true);
    final url =
        'https://generic-items-api-a785ff596d21.herokuapp.com/api/estadios/${widget.rm}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          estadios = data.map((json) => Estadio.fromJson(json)).toList();
          loading = false;
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar estádios')));
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> deleteEstadio(String id) async {
    final url =
        'https://generic-items-api-a785ff596d21.herokuapp.com/api/estadios/${widget.rm}/$id';
    try {
      final response = await http.delete(Uri.parse(url));
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Recarrega lista
        fetchEstadios();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Estádio excluído com sucesso')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao excluir estádio')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  void openForm() async {
    final bool? saved = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EstadioFormPage(rm: widget.rm)));
    if (saved == true) {
      fetchEstadios();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Estádios')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchEstadios,
              child: estadios.isEmpty
                  ? ListView(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text('Nenhum estádio cadastrado'),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: estadios.length,
                      itemBuilder: (context, index) {
                        final estadio = estadios[index];
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: ListTile(
                            leading: Image.network(
                              estadio.imagem,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.broken_image),
                            ),
                            title: Text(estadio.titulo),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(estadio.descricao),
                                Text('Capacidade: ${estadio.capacidade}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text('Confirmar exclusão'),
                                    content: Text(
                                      'Deseja realmente excluir o estádio "${estadio.titulo}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          deleteEstadio(estadio.id);
                                        },
                                        child: Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: openForm,
        child: Icon(Icons.add),
      ),
    );
  }
}

class EstadioFormPage extends StatefulWidget {
  final String rm;
  EstadioFormPage({required this.rm});

  @override
  _EstadioFormPageState createState() => _EstadioFormPageState();
}

class _EstadioFormPageState extends State<EstadioFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController imagemController = TextEditingController();
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController capacidadeController = TextEditingController();

  String? previewUrl;

  bool saving = false;

  void updatePreview() {
    setState(() {
      previewUrl = imagemController.text.trim();
    });
  }

  Future<void> saveEstadio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    final url =
        'https://generic-items-api-a785ff596d21.herokuapp.com/api/estadios';

    final body = {
      "rm": widget.rm,
      "imagem": imagemController.text.trim(),
      "titulo": tituloController.text.trim(),
      "descricao": descricaoController.text.trim(),
      "capacidade": int.parse(capacidadeController.text.trim()),
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Estádio salvo com sucesso')));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar estádio')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    imagemController.dispose();
    tituloController.dispose();
    descricaoController.dispose();
    capacidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Adicionar Estádio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: imagemController,
                decoration: InputDecoration(labelText: 'URL da imagem'),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a URL da imagem';
                  }
                  return null;
                },
                onChanged: (_) => updatePreview(),
              ),
              if (previewUrl != null && previewUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Image.network(
                    previewUrl!,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) =>
                        Text('Imagem inválida'),
                  ),
                ),
              TextFormField(
                controller: tituloController,
                decoration: InputDecoration(labelText: 'Título'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o título';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: descricaoController,
                decoration: InputDecoration(labelText: 'Descrição'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a descrição';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: capacidadeController,
                decoration: InputDecoration(labelText: 'Capacidade'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a capacidade';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Informe um número válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              saving
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: saveEstadio,
                      child: Text('Salvar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
