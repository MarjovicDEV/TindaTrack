import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/location/nominatim_client.dart';
import '../../../core/resources/app_copy.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  static const _kOwner = 'profile_owner_name';
  static const _kStore = 'profile_store_name';
  static const _kLoc = 'profile_location_display';

  final _owner = TextEditingController();
  final _store = TextEditingController();
  final _search = TextEditingController();
  NominatimClient? _nominatim;
  String _savedLocation = '';
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _nominatim = NominatimClient();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _owner.text = p.getString(_kOwner) ?? '';
      _store.text = p.getString(_kStore) ?? '';
      _savedLocation = p.getString(_kLoc) ?? '';
    });
  }

  Future<void> _saveFields() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kOwner, _owner.text.trim());
    await p.setString(_kStore, _store.text.trim());
  }

  Future<void> _pickLocation(String display) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLoc, display);
    setState(() => _savedLocation = display);
  }

  Future<void> _runSearch() async {
    final copy = AppCopy.of(context);
    final q = _search.text.trim();
    if (q.isEmpty || _nominatim == null) return;
    setState(() => _searching = true);
    try {
      final hits = await _nominatim!.search(q);
      if (!mounted) return;
      if (hits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(copy.searchNoResults)),
        );
        return;
      }
      final choice = await showDialog<LocationSuggestion>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(copy.pickLocationTitle),
          children: hits
              .map(
                (h) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, h),
                  child: Text(h.displayName, maxLines: 3, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
        ),
      );
      if (choice != null) {
        await _pickLocation(choice.displayName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _owner.dispose();
    _store.dispose();
    _search.dispose();
    _nominatim?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(copy.settingsProfileSection)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _owner,
            decoration: InputDecoration(labelText: copy.settingsOwnerName),
            onEditingComplete: _saveFields,
          ),
          TextField(
            controller: _store,
            decoration: InputDecoration(labelText: copy.settingsStoreName),
            onEditingComplete: _saveFields,
          ),
          const SizedBox(height: 8),
          Text(copy.settingsEmailSoon, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          Text(copy.settingsLocation, style: Theme.of(context).textTheme.titleSmall),
          if (_savedLocation.isNotEmpty) Text(_savedLocation),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: copy.settingsSearchLocation,
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(icon: const Icon(Icons.search), onPressed: _runSearch),
            ),
            onSubmitted: (_) => _runSearch(),
          ),
          const SizedBox(height: 8),
          Text(copy.settingsOsmAttribution, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
