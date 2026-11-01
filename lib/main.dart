import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.isEmpty || _supabaseKey.isEmpty) {
    runApp(const ProviderScope(child: ConfigurationApp()));
    return;
  }

  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabaseKey,
  );

  runApp(const ProviderScope(child: RitmeApp()));
}

final supabase = Supabase.instance.client;

class ConfigurationApp extends StatelessWidget {
  const ConfigurationApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF6D5CE8)),
        home: const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Konfigurasi Supabase belum tersedia. '
                'Build APK melalui GitHub Actions dengan repository secrets '
                'SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
}

class RitmeApp extends StatelessWidget {
  const RitmeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'RITME',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: const AuthGate(),
      );

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7566E8),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF101116)
          : const Color(0xFFF7F7FB),
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.dark
            ? const Color(0xFF1B1C24)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (supabase.auth.currentSession != null) return const MainShell();
          return const AuthPage();
        },
      );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.length < 6) {
      _message('Masukkan email dan password minimal 6 karakter.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_register) {
        await supabase.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'full_name': _name.text.trim()},
        );
        if (mounted) {
          _message('Pendaftaran dikirim. Periksa email jika verifikasi diaktifkan.');
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (e) {
      _message(e.message);
    } catch (_) {
      _message('Terjadi kesalahan koneksi. Coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.bolt_rounded, size: 34, color: color.primary),
                  ),
                  const SizedBox(height: 22),
                  Text('RITME', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Bangun progres, satu langkah setiap hari.', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 30),
                  if (_register) ...[
                    TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nama lengkap', prefixIcon: Icon(Icons.person_outline))),
                    const SizedBox(height: 12),
                  ],
                  TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
                  const SizedBox(height: 12),
                  TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: _busy
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_register ? 'Buat akun' : 'Masuk'),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => setState(() => _register = !_register),
                    child: Text(_register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = [
    DashboardPage(),
    TasksPage(),
    HabitsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Beranda'),
            NavigationDestination(icon: Icon(Icons.checklist_rounded), label: 'Tugas'),
            NavigationDestination(icon: Icon(Icons.track_changes_rounded), label: 'Habit'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
          ],
        ),
      );
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: supabase.from('tasks').select('id,status').order('created_at'),
          builder: (context, snapshot) {
            final tasks = snapshot.data ?? [];
            final completed = tasks.where((e) => e['status'] == 'completed').length;
            return RefreshIndicator(
              onRefresh: () async => await supabase.from('tasks').select('id,status'),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('RITME', style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 2, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Jaga ritmemu.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Mulai dari satu hal penting hari ini.'),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ringkasan tugas'),
                          const SizedBox(height: 12),
                          if (snapshot.hasError)
                            const Text('Belum bisa memuat tugas. Tarik layar untuk mencoba lagi.')
                          else if (snapshot.connectionState == ConnectionState.waiting)
                            const LinearProgressIndicator()
                          else ...[
                            Text('$completed / ${tasks.length}', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const Text('tugas selesai'),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(value: tasks.isEmpty ? 0 : completed / tasks.length),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: const ListTile(
                      leading: Icon(Icons.lightbulb_outline),
                      title: Text('Fokus pada progres, bukan kesempurnaan.'),
                      subtitle: Text('Tambahkan tugas dan kebiasaan kecil yang realistis.'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  String _filter = 'all';

  Future<List<Map<String, dynamic>>> _load() async {
    var query = supabase.from('tasks').select().order('created_at', ascending: false);
    if (_filter != 'all') query = query.eq('status', _filter);
    return query;
  }

  Future<void> _addTask() async {
    final title = TextEditingController();
    final description = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tugas baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'Nama tugas')),
            const SizedBox(height: 10),
            TextField(controller: description, decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      try {
        await supabase.from('tasks').insert({
          'user_id': supabase.auth.currentUser!.id,
          'title': title.text.trim(),
          'description': description.text.trim().isEmpty ? null : description.text.trim(),
        });
        if (mounted) setState(() {});
      } catch (_) {
        _notify('Tugas gagal disimpan. Periksa koneksi dan kebijakan database.');
      }
    }
    title.dispose();
    description.dispose();
  }

  Future<void> _toggle(Map<String, dynamic> task) async {
    final completed = task['status'] == 'completed';
    try {
      await supabase.from('tasks').update({
        'status': completed ? 'pending' : 'completed',
        'completed_at': completed ? null : DateTime.now().toUtc().toIso8601String(),
      }).eq('id', task['id']);
      if (mounted) setState(() {});
    } catch (_) {
      _notify('Status tugas gagal diperbarui.');
    }
  }

  Future<void> _delete(String id) async {
    try {
      await supabase.from('tasks').delete().eq('id', id);
      if (mounted) setState(() {});
    } catch (_) {
      _notify('Tugas gagal dihapus.');
    }
  }

  void _notify(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tugas')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addTask,
          icon: const Icon(Icons.add),
          label: const Text('Tambah tugas'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('Semua')),
                  ButtonSegment(value: 'pending', label: Text('Belum')),
                  ButtonSegment(value: 'completed', label: Text('Selesai')),
                ],
                selected: {_filter},
                onSelectionChanged: (value) => setState(() => _filter = value.first),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                key: ValueKey(_filter),
                future: _load(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return const _ErrorState(message: 'Gagal memuat tugas. Periksa koneksi internet dan RLS Supabase.');
                  final rows = snapshot.data ?? [];
                  if (rows.isEmpty) return const _EmptyState(icon: Icons.checklist_rounded, title: 'Belum ada tugas', message: 'Tambahkan tugas pertama lu.');
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final task = rows[index];
                      final done = task['status'] == 'completed';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Checkbox(value: done, onChanged: (_) => _toggle(task)),
                          title: Text(task['title'] ?? '', style: TextStyle(decoration: done ? TextDecoration.lineThrough : null)),
                          subtitle: task['description'] == null ? null : Text(task['description']),
                          trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(task['id'])),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  Future<List<Map<String, dynamic>>> _load() => supabase
      .from('habits')
      .select()
      .eq('is_active', true)
      .order('created_at', ascending: false);

  Future<void> _addHabit() async {
    final title = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kebiasaan baru'),
        content: TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'Contoh: Membaca 15 menit')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      try {
        await supabase.from('habits').insert({
          'user_id': supabase.auth.currentUser!.id,
          'title': title.text.trim(),
        });
        if (mounted) setState(() {});
      } catch (_) {
        _notify('Habit gagal disimpan. Periksa koneksi dan RLS.');
      }
    }
    title.dispose();
  }

  Future<void> _checkin(String habitId) async {
    final today = DateTime.now();
    final date = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    try {
      await supabase.from('habit_checkins').insert({
        'habit_id': habitId,
        'user_id': supabase.auth.currentUser!.id,
        'checkin_date': date,
      });
      if (mounted) _notify('Habit hari ini berhasil dicatat.');
    } on PostgrestException catch (e) {
      _notify(e.code == '23505' ? 'Habit ini sudah dicatat hari ini.' : 'Check-in gagal: ${e.message}');
    } catch (_) {
      _notify('Check-in gagal. Periksa koneksi.');
    }
  }

  void _notify(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Habit Tracker')),
        floatingActionButton: FloatingActionButton.extended(onPressed: _addHabit, icon: const Icon(Icons.add), label: const Text('Tambah habit')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _load(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return const _ErrorState(message: 'Gagal memuat habit. Periksa koneksi dan RLS Supabase.');
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) return const _EmptyState(icon: Icons.track_changes, title: 'Mulai bangun kebiasaan', message: 'Buat habit kecil yang ingin lu lakukan rutin.');
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final habit = rows[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.bolt)),
                    title: Text(habit['title'] ?? ''),
                    subtitle: const Text('Target: konsisten setiap hari'),
                    trailing: FilledButton.tonal(
                      onPressed: () => _checkin(habit['id']),
                      child: const Text('Check-in'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 34)),
          const SizedBox(height: 14),
          Center(child: Text(user?.email ?? 'Pengguna RITME', style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Keluar akun'),
              onTap: () async {
                await supabase.auth.signOut();
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text('RITME MVP • Data tersimpan di Supabase.'),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 14),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      );
}
