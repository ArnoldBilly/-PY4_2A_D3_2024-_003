import 'package:shared_preferences/shared_preferences.dart';
class CounterController {
  int _counter = 0;
  int _step = 10;
  final List<String> _history = [];
  
  int get value => _counter;
  int get step => _step;
  List<String> get history => _history;

  Future<void> loadData(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    _counter = prefs.getInt('counter_$userName') ?? 0;
    _history.clear();
    _history.addAll(prefs.getStringList('history_$userName') ?? []);
  }

  Future<void> _saveToLocal(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter_$userName', _counter);
    await prefs.setStringList('history_$userName', _history);
  }

  void updatestep(double newCounter, String userName) {
    int oldstep = _step;
    if (newCounter < 0) return;
    _step = newCounter.round();

    if (oldstep != step) {
      _addToHistory("Step diubah dari $oldstep menjadi $_step", userName);
    }
  }

  void increment(String userName) {
    _counter = _counter + _step;
    _addToHistory("Counter ditambah menjadi $_counter", userName);
    _saveToLocal(userName);
  }
  
  void decrement(String userName) {
    if (_counter > 0) {
    _counter = _counter - _step;
    }

    if (_counter <= 0) {
      _counter = 0;
      _addToHistory("Value: $_counter. Gagal melakukan decrement terhadap counter", userName);  
    }else if (_counter - _step < 0) {
      _counter = 0;
      _addToHistory("Value: $_counter. Gagal melakukan decrement terhadap counter", userName);  
    }else {
      _addToHistory("Counter dikurangi menjadi $_counter", userName);
    }

    _saveToLocal(userName);
  }

  void reset(String userName) {
    _counter = 0;
    _addToHistory("Counter direset menjadi $_counter", userName);
    _saveToLocal(userName);
  } 

  void _addToHistory(String message, String userName) {
    String jam = "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}";
    _history.insert(0, "[$jam] $userName: $message");
    if (history.length > 5) {
      _history.removeLast();
    }
  }
}