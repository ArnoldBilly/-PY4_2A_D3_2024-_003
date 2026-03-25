import 'package:logbook_app_001/features/logbook/model/log_model.dart';
import '../controller/log_controller.dart';
import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/onboarding/view/onboarding_view.dart';
import 'package:intl/intl.dart';
import '../../../services/access_control_service.dart';
import 'log_editor_page.dart';

class LogView extends StatefulWidget {
  final dynamic currentUser; 
  const LogView({super.key, required this.currentUser});

  @override
  State<LogView> createState() => _LogViewState();
}

class LogSearchDelegate extends SearchDelegate {
  final List<LogModel> allLogs;
  final Function(int, LogModel) onEdit;
  final Function(int) onDelete;

  LogSearchDelegate({
    required this.allLogs,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = allLogs.where((log) {
      return log.title.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final log = suggestions[index];
        return ListTile(
          title: Text(log.title),
          subtitle: Text(log.description),
          onTap: () {
            close(context, null);
            onEdit(allLogs.indexOf(log), log); 
          },
        );
      },
    );
  }
}

class _LogViewState extends State <LogView> {
  late LogController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Pekerjaan": return const Color.fromARGB(255, 135, 184, 225);
      case "Urgent": return const Color.fromARGB(255, 218, 135, 129);
      default: return const Color.fromARGB(255, 142, 224, 145);
    }
  }

  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  void _showEditLogDialog(int index, LogModel log) {
    _titleController.text = log.title;
    _contentController.text = log.description;

    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          controller: _controller, 
          currentUser: widget.currentUser,
          log: log,
          index: index,
        )
      )
    );
  }

  Widget _buildLogCard(LogModel log, int index) {
    final bool isOwner = log.authorId == widget.currentUser['uid'];
    
    final bool canEdit = AccessControlService.canPerform(
      widget.currentUser['role'],
      AccessControlService.actionUpdate,
      isOwner: isOwner,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: _getCategoryColor(log.category),
      child: ListTile(
        leading: Icon(
          log.id != null ? Icons.cloud_done : Icons.cloud_upload_outlined,
          color: log.id != null ? Colors.green : Colors.orange,
        ),
        title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(log.description),
        trailing: canEdit ?
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () => _showEditLogDialog(index, log),
        ) : null,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = LogController(
      userId: widget.currentUser['uid'],
      userRole: widget.currentUser['role'],
      teamId: widget.currentUser['teamId'],
    );
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    setState(() => _isLoading = true);
    try {
      await _controller.loadLogs(); 
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.currentUser['username']}"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: LogSearchDelegate(
                  allLogs: _controller.logsNotifier.value, 
                  onEdit: _showEditLogDialog,
                  onDelete: _controller.removeLog,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () {
              showDialog(
                context: context, 
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi Logout"),
                    content: const Text("Apakah anda yakin? Data yang belum disimpan mungkin hilang"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), 
                        child: const Text("Batal")
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context, 
                            MaterialPageRoute(builder: (context) => const OnBoardingView()), 
                            (route) => false
                          );
                        }, 
                        child: const Text(
                            "Ya, Keluar", 
                            style: TextStyle(color: Colors.red)
                          )
                        )
                    ],
                  );
                });
            })
        ],
      ),
      body: ValueListenableBuilder<List<LogModel>>(
        valueListenable: _controller.logsNotifier,
        builder: (context, currentLogs, child) {
          if (_isLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Menghubungkan ke MongoDB Atlas..."),
                ],
              ),
            );
          }
          final displayLogs = currentLogs.where((log) {
            return log.authorId == widget.currentUser['uid'] || log.isPublic == true;
          }).toList();
          if (displayLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Belum ada catatan di Cloud."),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _goToEditor,
                    child: const Text("Buat Catatan Pertama"),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _controller.loadLogs();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Data diperbarui dari cloud"))
                );
              }
            },
            child: ListView.builder(
                itemCount: displayLogs.length,
                itemBuilder: (context, index) {
                  final log = displayLogs[index];
                  // Di dalam ListView.builder
                  final bool canDelete = AccessControlService.canPerform(
                    widget.currentUser['role'], 
                    AccessControlService.actionDelete, 
                    isOwner: log.authorId == widget.currentUser['uid']
                  );

                  if (!canDelete) {
                    // Jika tidak punya izin, kembalikan ListTile biasa tanpa Dismissible
                    return _buildLogCard(log, index); 
                  }

                  return Dismissible(
                    key: Key('${log.id}_$index'), 
                    
                    direction: DismissDirection.endToStart,
                    
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Konfirmasi hapus?"),
                          content: Text("Apakah anda yakin menghapus catatan '${log.title}'?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Batal"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    
                    onDismissed: (direction) {
                      final logToDelete = displayLogs[index];
                      final originalIndex = _controller.logsNotifier.value.indexOf(logToDelete);
                      _controller.removeLog(originalIndex);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Catatan '${logToDelete.title}' berhasil dihapus")),
                      );
                    },
                    
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: _getCategoryColor(log.category), 
                      child: ListTile(
                        leading: Icon(
                          log.id != null ? Icons.cloud_done : Icons.cloud_upload_outlined,
                          color: log.id != null ? Colors.green : Colors.orange,
                        ),
                        title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log.description),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, d MMM yyyy - HH:mm', 'id_ID').format(DateTime.parse(log.date)),
                              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                            )
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditLogDialog(index, log),
                        ),
                      ),
                    ),
                  );
                },
              )
            );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToEditor(),
        child: const Icon(Icons.add),
      ),

    );
  }
}