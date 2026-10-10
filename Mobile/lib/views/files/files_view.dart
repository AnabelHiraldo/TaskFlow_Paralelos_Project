import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class FilesView extends StatefulWidget {
  const FilesView({super.key});

  @override
  State<FilesView> createState() => _FilesViewState();
}

class _FilesViewState extends State<FilesView> {
  final ApiService _api = ApiService();
  final List<Map<String, dynamic>> _files = [];
  bool _uploading = false;
  final Set<int> _deletingIds = {};

  Future<void> _pickAndUpload() async {
    try {

      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

      if (result.isEmpty) return;

      final file = result.first;
      final path = file.path;

      if (path == null) {
        _showMessage('No se pudo acceder a la ruta del archivo.');
        return;
      }

      setState(() => _uploading = true);

      final uploaded = await _api.uploadFile(
        filePath: path,
        filename: file.name,
      );

      if (!mounted) return;

      setState(() {
        _files.insert(0, uploaded);
        _uploading = false;
      });

      _showMessage('Archivo cargado correctamente.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _showMessage('Error al cargar el archivo: $e');
    }
  }

  Future<void> _deleteFile(Map<String, dynamic> file) async {
    final id = int.tryParse('${file['id']}');

    if (id == null) {
      _showMessage('No se encontró el identificador del archivo.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar archivo'),
        content: Text(
          '¿Deseas eliminar "${file['filename'] ?? 'este archivo'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingIds.add(id));

    try {
      await _api.deleteFile(id);

      if (!mounted) return;

      setState(() {
        _files.removeWhere(
          (item) => '${item['id']}' == '$id',
        );
        _deletingIds.remove(id);
      });

      _showMessage('Archivo eliminado.');
    } catch (e) {
      if (!mounted) return;

      setState(() => _deletingIds.remove(id));
      _showMessage('Error al eliminar el archivo: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatSize(dynamic value) {
    final bytes = int.tryParse('$value') ?? 0;

    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archivos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _uploading ? null : _pickAndUpload,
                icon: const Icon(Icons.upload_file),
                label: Text(
                  _uploading ? 'Cargando archivo...' : 'Seleccionar archivo',
                ),
              ),
            ),
          ),
          if (_uploading)
            const LinearProgressIndicator(),
          Expanded(
            child: _files.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Todavía no has cargado archivos en esta sesión.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (context, index) {
                      final file = _files[index];
                      final id = int.tryParse('${file['id']}');
                      final deleting =
                          id != null && _deletingIds.contains(id);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.insert_drive_file),
                          title: Text(
                            '${file['filename'] ?? 'Archivo'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${file['content_type'] ?? 'Tipo desconocido'}'
                            ' • ${_formatSize(file['size'])}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Eliminar archivo',
                            onPressed:
                                deleting ? null : () => _deleteFile(file),
                            icon: deleting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.delete_outline),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

