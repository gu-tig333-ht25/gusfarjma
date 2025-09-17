import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

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

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final inputController = TextEditingController();
  final List<Map<String, dynamic>> _todos = [
    {'title': 'Write a book', 'done': false},
    {'title': 'Do homework', 'done': false},
    {'title': 'Tidy room', 'done': true},
    {'title': 'Watch TV', 'done': false},
    {'title': 'Nap', 'done': false},
    {'title': 'Shop groceries', 'done': false},
    {'title': 'Have fun', 'done': false},
    {'title': 'Meditate', 'done': false},
  ];
  TodoFilter _filter = TodoFilter.all;

  List<Map<String, dynamic>> get _visible => switch (_filter) {
        TodoFilter.done => _todos.where((t) => t['done'] == true).toList(),
        TodoFilter.undone => _todos.where((t) => t['done'] == false).toList(),
        TodoFilter.all => _todos,
      };

  int _realIndex(int i) => _todos.indexOf(_visible[i]);

  void _add() {
    final t = inputController.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _todos.insert(0, {'title': t, 'done': false});
      inputController.clear();
    });
  }

  void _toggle(int i) {
    final idx = _realIndex(i);
    if (idx < 0) return;
    setState(() => _todos[idx]['done'] = !_todos[idx]['done']);
  }

  void _remove(int i) {
    setState(() => _todos.remove(_visible[i]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: kPinkLight,
        elevation: 0,
        title: const Text(
          'TIG333 TODO',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          card(Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(children: [
              TextField(
                controller: inputController,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'What are you going to do?',
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(borderSide: BorderSide(color: kPinkLight)),
                ),
                onSubmitted: (_) => _add(),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                  onTap: _add,
                  child: const Text('+ ADD', style: TextStyle(color: kPink))),
            ]),
          )),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FilterTab('All', _filter == TodoFilter.all,
                onTap: () => setState(() => _filter = TodoFilter.all)),
            const SizedBox(width: 8),
            FilterTab('Done', _filter == TodoFilter.done,
                onTap: () => setState(() => _filter = TodoFilter.done)),
            const SizedBox(width: 8),
            FilterTab('Undone', _filter == TodoFilter.undone,
                onTap: () => setState(() => _filter = TodoFilter.undone)),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: card(Stack(children: [
              ListView.separated(
                padding: const EdgeInsets.only(bottom: 64),
                itemCount: _visible.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 1, child: ColoredBox(color: kPinkLight)),
                itemBuilder: (_, i) {
                  final t = _visible[i];
                  return GestureDetector(
                    onTap: () => _toggle(i),
                    child: todoRow(
                      t['title'] as String,
                      t['done'] as bool,
                      onToggle: () => _toggle(i),
                      onDelete: () => _remove(i),
                    ),
                  );
                },
              ),
              Positioned(
                  right: 12,
                  bottom: 12,
                  child: SmallPlusButton(onPressed: _add)),
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
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? Colors.pink.shade200 : Colors.black87))),
        InkWell(
          onTap: onDelete,
          child: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Text('x', style: TextStyle(fontSize: 18, color: kPink)),
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
          ? const Icon(Icons.check, size: 14, color: kPink)
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: kPink, width: selected ? 2 : 1)),
          child: Text(label,
              style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
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
              width: 36, height: 36, child: Icon(Icons.add, size: 22, color: kPink)),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: kPink),
            ),
          ),
        ),
      );
}
