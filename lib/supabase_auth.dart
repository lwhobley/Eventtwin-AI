import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_workspace.dart';

class SupabaseConfigurationPage extends StatelessWidget {
  const SupabaseConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Connect EventTwin AI')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supabase publishable key required',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Project URL is configured. Add this project’s publishable key to a local file named supabase.local.json, then run Flutter with --dart-define-from-file=supabase.local.json. The key is read at build time and must not be committed.',
              ),
              const SizedBox(height: 12),
              const SelectableText(
                '{\n  "SUPABASE_URL": "https://akkhcudeomnaxtplftmu.supabase.co",\n  "SUPABASE_PUBLISHABLE_KEY": "<paste locally>"\n}',
                style: TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 12),
              const Text(
                'After the key is configured, apply the migration in supabase/migrations before creating accounts.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SupabaseAuthGate extends StatelessWidget {
  const SupabaseAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        if (session == null) return const SupabaseAuthPage();
        return OrganizationChooser(user: session.user);
      },
    );
  }
}

class SupabaseAuthPage extends StatefulWidget {
  const SupabaseAuthPage({super.key});

  @override
  State<SupabaseAuthPage> createState() => _SupabaseAuthPageState();
}

class _SupabaseAuthPageState extends State<SupabaseAuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _createAccount = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (_createAccount) {
        final response = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'full_name': _name.text.trim()},
        );
        if (response.session == null) {
          _message = 'Check your email to confirm the account, then sign in.';
        }
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (error) {
      _message = error.message;
    } catch (_) {
      _message =
          'Could not connect to Supabase. Check the project URL and network.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Enter your email address first.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _message = 'If an account exists for that address, password reset instructions were sent.';
    } on AuthException catch (error) {
      _message = error.message;
    } catch (_) {
      _message = 'Could not send the password reset request.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'EventTwin AI',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _createAccount
                      ? 'Create your account'
                      : 'Sign in to your workspace',
                ),
                if (_createAccount)
                  TextField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _password,
                  obscureText: true,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(
                    _busy
                        ? 'Please wait…'
                        : _createAccount
                        ? 'Create account'
                        : 'Sign in',
                  ),
                ),
                if (!_createAccount)
                  TextButton(
                    onPressed: _busy ? null : _resetPassword,
                    child: const Text('Forgot password?'),
                  ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _createAccount = !_createAccount;
                          _message = null;
                        }),
                  child: Text(
                    _createAccount
                        ? 'Already registered? Sign in'
                        : 'Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class OrganizationChooser extends StatefulWidget {
  const OrganizationChooser({super.key, required this.user});
  final User user;

  @override
  State<OrganizationChooser> createState() => _OrganizationChooserState();
}

class _OrganizationChooserState extends State<OrganizationChooser> {
  late Future<List<Map<String, dynamic>>> _organizations;
  Map<String, dynamic>? _selected;
  String? _error;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _organizations = _loadOrganizations();
  }

  Future<List<Map<String, dynamic>>> _loadOrganizations() async {
    final rows = await _client
        .from('organization_members')
        .select('organization_id,role,organizations!inner(id,name)')
        .eq('user_id', widget.user.id);
    return rows.map((row) {
      final organization = row['organizations'] as Map<String, dynamic>;
      return {...organization, 'role': row['role']};
    }).toList();
  }

  Future<void> _createOrganization() async {
    final name = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create organization'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Organization name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (confirmed != true || name.text.trim().isEmpty) {
      name.dispose();
      return;
    }
    try {
      final id = await _client.rpc(
        'create_organization',
        params: {'organization_name': name.text.trim()},
      );
      if (!mounted) return;
      setState(() {
        _selected = {
          'id': id.toString(),
          'name': name.text.trim(),
          'role': 'owner',
        };
        _error = null;
      });
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Organization creation failed. Apply the database migration and retry.',
        );
      }
    } finally {
      name.dispose();
    }
  }

  Future<void> _signOut() => _client.auth.signOut();

  @override
  Widget build(BuildContext context) {
    if (_selected != null) {
      return CloudWorkspacePage(
        key: ValueKey(_selected!['id']),
        organization: _selected!,
        onBack: () => setState(() {
          _selected = null;
          _organizations = _loadOrganizations();
        }),
        onSignOut: _signOut,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose an organization'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _organizations,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not load organizations. Apply the tenant foundation migration and check your account access.',
                    ),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _signOut,
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final organizations = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Signed in as ${widget.user.email ?? widget.user.id}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 18),
                  for (final organization in organizations)
                    Card(
                      child: ListTile(
                        title: Text(organization['name'] as String),
                        subtitle: Text('Role: ${organization['role']}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => setState(() => _selected = organization),
                      ),
                    ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: _createOrganization,
                    icon: const Icon(Icons.add),
                    label: const Text('Create organization'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
