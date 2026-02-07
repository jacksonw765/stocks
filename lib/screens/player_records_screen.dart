import 'package:flutter/material.dart';
import '../utils/storage_helper.dart';
import '../theme/app_theme.dart';

/// Player records screen - all-time statistics
class PlayerRecordsScreen extends StatefulWidget {
  const PlayerRecordsScreen({super.key});

  @override
  State<PlayerRecordsScreen> createState() => _PlayerRecordsScreenState();
}

class _PlayerRecordsScreenState extends State<PlayerRecordsScreen> {
  Map<String, Map<String, dynamic>> _records = {};
  bool _isLoading = true;
  String _sortBy = 'wins';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await StorageHelper.getPlayerRecords();
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  List<MapEntry<String, Map<String, dynamic>>> get _sortedRecords {
    final entries = _records.entries.toList();

    switch (_sortBy) {
      case 'wins':
        entries.sort(
          (a, b) => (b.value['gamesWon'] as int).compareTo(
            a.value['gamesWon'] as int,
          ),
        );
        break;
      case 'played':
        entries.sort(
          (a, b) => (b.value['gamesPlayed'] as int).compareTo(
            a.value['gamesPlayed'] as int,
          ),
        );
        break;
      case 'highScore':
        entries.sort(
          (a, b) => (b.value['allTimeHighestStock'] as int).compareTo(
            a.value['allTimeHighestStock'] as int,
          ),
        );
        break;
      case 'name':
        entries.sort((a, b) => a.key.compareTo(b.key));
        break;
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Records'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            initialValue: _sortBy,
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'wins', child: Text('Sort by Wins')),
              const PopupMenuItem(
                value: 'played',
                child: Text('Sort by Games Played'),
              ),
              const PopupMenuItem(
                value: 'highScore',
                child: Text('Sort by Highest Stock'),
              ),
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No records yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Play some games to build your history!',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sortedRecords.length,
              itemBuilder: (context, index) {
                final entry = _sortedRecords[index];
                final name = entry.key;
                final record = entry.value;
                final gamesPlayed = record['gamesPlayed'] as int;
                final gamesWon = record['gamesWon'] as int;
                final highestStock = record['allTimeHighestStock'] as int;
                final winRate = gamesPlayed > 0
                    ? (gamesWon / gamesPlayed * 100).toStringAsFixed(0)
                    : '0';

                return Dismissible(
                  key: ValueKey(name),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppTheme.dangerRed,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Record?'),
                        content: Text('Remove all records for $name?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.dangerRed,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    final newRecords = Map<String, Map<String, dynamic>>.from(
                      _records,
                    );
                    newRecords.remove(name);
                    await StorageHelper.savePlayerRecords(newRecords);
                    setState(() => _records = newRecords);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: gamesWon > 0
                            ? AppTheme.accentGold
                            : Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: gamesWon > 0
                                ? Colors.white
                                : Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('$gamesWon wins · $gamesPlayed games'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            children: [
                              _StatChip(
                                icon: Icons.emoji_events,
                                label: 'Wins',
                                value: '$gamesWon',
                                color: AppTheme.accentGold,
                              ),
                              const SizedBox(width: 12),
                              _StatChip(
                                icon: Icons.percent,
                                label: 'Win Rate',
                                value: '$winRate%',
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              _StatChip(
                                icon: Icons.trending_up,
                                label: 'Best Stock',
                                value: '$highestStock',
                                color: AppTheme.secondaryColor,
                              ),
                            ],
                          ),
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
