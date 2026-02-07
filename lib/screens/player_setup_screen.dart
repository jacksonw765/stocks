import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../models/game_state.dart';
import '../providers/settings_provider.dart';
import '../utils/storage_helper.dart';

/// Player setup screen - add/remove/reorder players and configure game
class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final _nameController = TextEditingController();
  final List<String> _players = [];
  List<String> _savedPlayers = [];
  bool _isLoadingSaved = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPlayers();
  }

  Future<void> _loadSavedPlayers() async {
    final saved = await StorageHelper.getSavedPlayerNames();
    setState(() {
      _savedPlayers = saved;
      _isLoadingSaved = false;
    });
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_players.contains(name)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Player already added')));
      return;
    }
    setState(() {
      _players.add(name);
      if (!_savedPlayers.contains(name)) {
        _savedPlayers.add(name);
        StorageHelper.addPlayerName(name);
      }
    });
    _nameController.clear();
  }

  void _removePlayer(int index) {
    setState(() {
      _players.removeAt(index);
    });
  }

  void _addSavedPlayer(String name) {
    if (_players.contains(name)) return;
    setState(() {
      _players.add(name);
    });
  }

  void _startGame() {
    if (_players.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Need at least 2 players')));
      return;
    }

    final settings = context.read<SettingsProvider>();
    final players = _players
        .map((name) => Player(id: UniqueKey().toString(), name: name))
        .toList();

    final gameState = GameState(
      players: players,
      totalRounds: settings.totalRounds,
      oneStockPerRoll: settings.oneStockPerRoll,
    );

    Navigator.pushReplacementNamed(context, '/game', arguments: gameState);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add player input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter player name',
                      prefixIcon: Icon(Icons.person_add),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addPlayer(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _addPlayer, child: const Text('Add')),
              ],
            ),
          ),

          // Current players list
          Expanded(
            child: _players.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Add players to start',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _players.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final player = _players.removeAt(oldIndex);
                        _players.insert(newIndex, player);
                      });
                    },
                    itemBuilder: (context, index) {
                      return Card(
                        key: ValueKey(_players[index]),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            _players[index],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => _removePlayer(index),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Saved players section
          if (!_isLoadingSaved && _savedPlayers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Add',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _savedPlayers
                        .where((name) => !_players.contains(name))
                        .take(6)
                        .map(
                          (name) => ActionChip(
                            label: Text(name),
                            onPressed: () => _addSavedPlayer(name),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

          // Game settings and start button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Round selector
                  Row(
                    children: [
                      Text(
                        'Rounds:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 10, label: Text('10')),
                            ButtonSegment(value: 15, label: Text('15')),
                            ButtonSegment(value: 20, label: Text('20')),
                          ],
                          selected: {settings.totalRounds},
                          onSelectionChanged: (value) {
                            settings.setTotalRounds(value.first);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Variant toggle
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'One stock per roll',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                      Switch(
                        value: settings.oneStockPerRoll,
                        onChanged: (value) =>
                            settings.setOneStockPerRoll(value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Start game button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _players.length >= 2 ? _startGame : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _players.length >= 2
                            ? 'Start Game (${_players.length} players)'
                            : 'Add at least 2 players',
                      ),
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
