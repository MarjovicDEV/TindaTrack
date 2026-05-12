import 'dart:async';

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
    if (!mounted) return;

    if (_owner.text.isEmpty) {
      _owner.text = p.getString(_kOwner) ?? '';
    }
    if (_store.text.isEmpty) {
      _store.text = p.getString(_kStore) ?? '';
    }
    setState(() {
      _savedLocation = p.getString(_kLoc) ?? '';
    });
  }

  Future<void> _persistOwnerStore(String owner, String store) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kOwner, owner);
    await p.setString(_kStore, store);
  }

  Future<void> _saveFields() async {
    await _persistOwnerStore(_owner.text.trim(), _store.text.trim());
  }

  Future<void> _saveProfileAndConfirm() async {
    FocusScope.of(context).unfocus();
    await _saveFields();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppCopy.of(context).settingsProfileSaved)),
    );
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
    unawaited(_persistOwnerStore(_owner.text.trim(), _store.text.trim()));
    _owner.dispose();
    _store.dispose();
    _search.dispose();
    _nominatim?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget sectionHeader(IconData icon, String title) {
      return Row(
        children: [
          Icon(icon, size: 22, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(copy.settingsProfileSection)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _owner,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: copy.settingsOwnerName,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    onEditingComplete: _saveFields,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _store,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: copy.settingsStoreName,
                      prefixIcon: const Icon(Icons.store_outlined),
                    ),
                    onEditingComplete: _saveFields,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _saveProfileAndConfirm,
                    icon: const Icon(Icons.save_outlined, size: 20),
                    label: Text(copy.settingsProfileSave),
                  ),
                  const SizedBox(height: 20),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.mark_email_unread_outlined,
                            size: 20,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              copy.settingsEmailSoon,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionHeader(Icons.place_outlined, copy.settingsLocation),
                  const SizedBox(height: 4),
                  if (_savedLocation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.65),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 22,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _savedLocation,
                                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: _savedLocation.isEmpty ? 16 : 20),
                  TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: copy.settingsSearchLocation,
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.search),
                              tooltip: MaterialLocalizations.of(context).searchFieldLabel,
                              onPressed: _runSearch,
                            ),
                    ),
                    onSubmitted: (_) => _runSearch(),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    copy.settingsOsmAttribution,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
