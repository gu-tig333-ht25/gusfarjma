import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

void main() => runApp(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => TodoProvider())],
        child: const MyApp(),
      ),
    );

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: TodoPage(),
      );
}

enum TodoFilter { all, done, undone }

const kBg = Color(0xFFFFF0F5);
const kPink = Colors.pink;
const kPinkLight = Color(0xFFFFC0CB);
const kBorder = kPink;

class TodoProvider extends ChangeNotifier {
  static const _apiKey = '0ca022f8-c332-4447-b33f-859fa2ed787c';
  static const _base = 'https://todoapp-api.apps.k8s.gu.se';

  final inputController = TextEditingController();
  final List<Map<String, dynamic>> _todos = [];
  TodoFilter _filter = TodoFilter.all;
  bool _syncedOnce = false;
  bool _syncInProgress = false;

  List<Map<String, dynamic>> get visible => switch (_filter) {
        TodoFilter.done => _todos.where((t) => t['done'] == true).toList(),
        TodoFilter.undone => _todos.where((t) => t['done'] == false).toList(),
        TodoFilter.all => _todos,
      };

  int realIndex(int i) => _todos.indexOf(visible[i]);
  void setFilter(TodoFilter f) {
    _filter = f;
    notifyListeners();
  }

  void syncIfNeeded() {
    if (_syncedOnce || _syncInProgress) return;
    _syncedOnce = true;
    _syncFromServer();
  }

  Future<void> add() async {
    final t = inputController.text.trim();
    if (t.isEmpty) return;
    inputController.clear();
    try {
      final listFromServer = await _apiCreate(t);
      _replaceAllWithServer(listFromServer);
    } catch (e) {
      debugPrint('API-fel i add(): $e');
    }
  }

  Future<void> toggle(int i) async {
    final idx = realIndex(i);
    if (idx < 0) return;
    final item = Map<String, dynamic>.from(_todos[idx]);
    final hasId = (item['id'] as String?)?.isNotEmpty == true;
    final newDone = !(item['done'] as bool);
    if (hasId) {
      try {
        final updated = await _apiUpdate(
            id: item['id'] as String,
            title: item['title'] as String,
            done: newDone);
        _todos[idx] = updated;
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('API-fel i toggle(): $e');
      }
    }
    _todos[idx]['done'] = newDone;
    notifyListeners();
  }

  Future<void> removeAtVisible(int i) async {
    final item = Map<String, dynamic>.from(visible[i]);
    final hasId = (item['id'] as String?)?.isNotEmpty == true;
    if (hasId) {
      try {
        await _apiDelete(item['id'] as String);
        _todos.removeWhere((t) => t['id'] == item['id']);
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('API-fel i remove(): $e');
      }
    }
    _todos.remove(item);
    notifyListeners();
  }

  Uri _u(String path, [Map<String, String>? qp]) =>
      Uri.parse('$_base$path')
          .replace(queryParameters: {'key': _apiKey, ...?qp});

  Future<void> _syncFromServer() async {
    _syncInProgress = true;
    try {
      final list = await _apiList();
      _replaceAllWithServer(list);
    } catch (e) {
      debugPrint('sync error: $e');
    } finally {
      _syncInProgress = false;
    }
  }

  void _replaceAllWithServer(List<Map<String, dynamic>> serverList) {
    _todos..clear()..addAll(serverList);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> _apiList() async {
    final r = await http.get(_u('/todos'));
    _ok(r);
    final data = jsonDecode(r.body) as List;
    return data
        .map((e) =>
            {'id': e['id'], 'title': e['title'], 'done': e['done']})
        .toList();
  }

  Future<List<Map<String, dynamic>>> _apiCreate(String title,
      {bool done = false}) async {
    final r = await http.post(_u('/todos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'done': done}));
    _ok(r);
    final data = jsonDecode(r.body) as List;
    return data
        .map((e) =>
            {'id': e['id'], 'title': e['title'], 'done': e['done']})
        .toList();
  }

  Future<Map<String, dynamic>> _apiUpdate(
      {required String id,
      required String title,
      required bool done}) async {
    final r = await http.put(_u('/todos/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'done': done}));
    _ok(r);
    final e = jsonDecode(r.body) as Map<String, dynamic>;
    return {'id': e['id'], 'title': e['title'], 'done': e['done']};
  }

  Future<void> _apiDelete(String id) async {
    final r = await http.delete(_u('/todos/$id'));
    _ok(r);
  }

  void _ok(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }
  }
}

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});
  @override
  Widget build(BuildContext context) {
    context.read<TodoProvider>().syncIfNeeded();
    final p = context.watch<TodoProvider>();
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: kPinkLight,
        elevation: 0,
        title: const Text('TIG333 TODO',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          card(Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(children: [
              TextField(
                controller: p.inputController,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'What are you going to do?',
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: kPinkLight)),
                ),
                onSubmitted: (_) =>
                    context.read<TodoProvider>().add(),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => context.read<TodoProvider>().add(),
                child: const Text('+ ADD',
                    style: TextStyle(color: kPink)),
              ),
            ]),
          )),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FilterTab('All', p._filter == TodoFilter.all,
                onTap: () => context
                    .read<TodoProvider>()
                    .setFilter(TodoFilter.all)),
            const SizedBox(width: 8),
            FilterTab('Done', p._filter == TodoFilter.done,
                onTap: () => context
                    .read<TodoProvider>()
                    .setFilter(TodoFilter.done)),
            const SizedBox(width: 8),
            FilterTab('Undone', p._filter == TodoFilter.undone,
                onTap: () => context
                    .read<TodoProvider>()
                    .setFilter(TodoFilter.undone)),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: card(Stack(children: [
              ListView.separated(
                padding: const EdgeInsets.only(bottom: 64),
                itemCount: p.visible.length,
                separatorBuilder: (_, __) => const SizedBox(
                    height: 1,
                    child: ColoredBox(color: kPinkLight)),
                itemBuilder: (_, i) {
                  final t = p.visible[i];
                  return GestureDetector(
                    onTap: () =>
                        context.read<TodoProvider>().toggle(i),
                    child: todoRow(
                      t['title'] as String,
                      t['done'] as bool,
                      onToggle: () =>
                          context.read<TodoProvider>().toggle(i),
                      onDelete: () => context
                          .read<TodoProvider>()
                          .removeAtVisible(i),
                    ),
                  );
                },
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: SmallPlusButton(
                    onPressed: () =>
                        context.read<TodoProvider>().add()),
              ),
            ])),
          ),
        ]),
      ),
    );
  }
}

Widget card(Widget child) => Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kBorder)),
      child: child,
    );

Widget todoRow(String title, bool done,
        {VoidCallback? onToggle, VoidCallback? onDelete}) =>
    SizedBox(
      height: 46,
      child: Row(children: [
        const SizedBox(width: 8),
        GestureDetector(onTap: onToggle, child: checkBox(done)),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title,
                style: TextStyle(
                    decoration: done
                        ? TextDecoration.lineThrough
                        : null,
                    color: done
                        ? Colors.pink.shade200
                        : Colors.black87))),
        InkWell(
          onTap: onDelete,
          child: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Text('x',
                style:
                    TextStyle(fontSize: 18, color: kPink)),
          ),
        ),
      ]),
    );

Widget checkBox(bool checked) => Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
          border: Border.all(color: kPink, width: 1.4),
          borderRadius: BorderRadius.circular(2),
          color: checked ? kPinkLight : Colors.white),
      alignment: Alignment.center,
      child: checked
          ? const Icon(Icons.check,
              size: 14, color: kPink)
          : null,
    );

class FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const FilterTab(this.label, this.selected, {super.key, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border:
                  Border.all(color: kPink, width: selected ? 2 : 1)),
          child: Text(label,
              style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? kPink : Colors.black87)),
        ),
      );
}

class SmallPlusButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const SmallPlusButton({super.key, this.onPressed});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: kPink),
              boxShadow: const [
                BoxShadow(
                    blurRadius: 6,
                    offset: Offset(0, 2),
                    color: Color(0x22000000))
              ]),
          child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.add,
                  size: 22, color: kPink)),
        ),
      );
}

class DisabledTextField extends StatelessWidget {
  final String hint;
  const DisabledTextField(this.hint, {super.key});
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: TextField(
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 10),
            border: const OutlineInputBorder(
              borderSide: BorderSide(
                  color: Color.fromARGB(255, 230, 29, 96)),
            ),
          ),
        ),
      );
}