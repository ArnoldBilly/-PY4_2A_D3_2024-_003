import '../controller/counter_controller.dart';
import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/onboarding/view/onboarding_view.dart';

class CounterView extends StatefulWidget {
  final String username;
  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  Future<void> _setupData() async {
    await _controller.loadData(widget.username); 
    if (mounted) {
      setState(() {});
    }
  }
  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return "Selamat Pagi";
    if (hour < 17) return "Selamat Siang";
    return "Selamat Malam";
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Reset"),
          content: const Text("Apakah Anda yakin ingin menghapus semua hitungan? Aksi ini tidak dapat dibatalkan."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                setState(() => _controller.reset(widget.username));
                Navigator.pop(context);
              },
              child: const Text("Ya, Reset", style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _setupData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.username}"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi Logout"),
                    content: const Text("Apakah Anda yakin? Data yang belum disimpan mungkin akan hilang."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); 
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const OnBoardingView()),
                            (route) => false,
                          );
                        },
                        child: const Text("Ya, Keluar", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Text("${getGreeting()}, ${widget.username}!", style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(
            '${_controller.value}',
            style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
          ),
          Text("Step: ${_controller.step}"),
          Slider(
            value: _controller.step.toDouble(),
            min: 1, max: 20, divisions: 19,
            onChanged: (val) => setState(() => _controller.updatestep(val, widget.username)),
          ),
          const Divider(),
          const Text("Riwayat Aktivitas (Maks 5)", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: _controller.history.length,
              itemBuilder: (context, index) {
                String textRiwayat = _controller.history[index];
                Color warnaTeks;
                if (textRiwayat.contains("ditambah")) {
                  warnaTeks = Colors.green;
                } else if (textRiwayat.contains("dikurang")) {
                  warnaTeks = Colors.red;
                } else if (textRiwayat.contains("direset")) {
                  warnaTeks = Colors.orange;
                } else {
                  warnaTeks = Colors.blueGrey;
                }

                return ListTile(
                  leading: Icon(Icons.circle, color: warnaTeks, size: 12),
                  title: Text(
                    textRiwayat,
                    style: TextStyle(
                      color: warnaTeks, 
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: "minus",
                  backgroundColor: Colors.red,
                  onPressed: () => setState(() => _controller.decrement(widget.username)),
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: "reset",
                  backgroundColor: Colors.orange,
                  onPressed: _showResetConfirmation,
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: "plus",
                  backgroundColor: Colors.green,
                  onPressed: () => setState(() => _controller.increment(widget.username)),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}