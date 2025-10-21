import 'package:flutter/material.dart';
import 'database_helper.dart';

final dbHelper = DatabaseHelper();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dbHelper.init(); // ensure DB is ready
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FolderScreen(),
    );
  }
}

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  final List<Map<String, String>> suits = const [
    {'name': 'Spades'},
    {'name': 'Hearts'},
    {'name': 'Diamonds'},
    {'name': 'Clubs'},
  ];

  List<Map<String, dynamic>> unassignedCards = [];
  String? selectedCard;
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeDeck();
  }

  Future<void> _initializeDeck() async {
    // Load unassigned cards (folderId = 0) or create them if they don't exist
    final existing = await dbHelper.queryCards(0);
    if (existing.isEmpty) {
      for (var suit in suits) {
        for (int i = 1; i <= 10; i++) {
          await dbHelper.insertCard({
            DatabaseHelper.columnName: '$i of ${suit['name']}',
            DatabaseHelper.columnSuit: suit['name']!,
            DatabaseHelper.columnFolderId: 0, // unassigned
          });
        }
      }
    }
    unassignedCards = await dbHelper.queryCards(0);
  }

  Future<void> _assignCardToFolder(String cardName, String folderName) async {
    final card = unassignedCards.firstWhere((c) => c[DatabaseHelper.columnName] == cardName);
    await dbHelper.updateCard({
      DatabaseHelper.columnId: card[DatabaseHelper.columnId],
      DatabaseHelper.columnName: cardName,
      DatabaseHelper.columnSuit: folderName,
      DatabaseHelper.columnFolderId: folderName.hashCode,
    });
    // Refresh unassigned cards
    unassignedCards = await dbHelper.queryCards(0);
    setState(() {
      selectedCard = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Folders'), centerTitle: true),
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Unassigned Cards
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  children: unassignedCards.map((card) {
                    final name = card[DatabaseHelper.columnName]!;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCard = name;
                        });
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: selectedCard == name ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selectedCard == name ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Folders Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: suits.length,
                  itemBuilder: (context, index) {
                    final suit = suits[index];
                    return GestureDetector(
                      onTap: () async {
                        if (selectedCard != null) {
                          await _assignCardToFolder(selectedCard!, suit['name']!);
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CardScreen(suitName: suit['name']!),
                          ),
                        );
                      },
                      child: Card(
                        child: Center(
                          child: Text(
                            suit['name']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CardScreen extends StatefulWidget {
  final String suitName;

  const CardScreen({super.key, required this.suitName});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  List<Map<String, dynamic>> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await dbHelper.queryCards(widget.suitName.hashCode);
    setState(() {
      _cards = cards;
    });
  }

  void _deleteCard(int id) async {
    await dbHelper.deleteCard(id);
    _loadCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.suitName} Cards')),
      body: _cards.isEmpty
          ? const Center(child: Text('No cards yet.'))
          : ListView.builder(
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return ListTile(
                  title: Text(card[DatabaseHelper.columnName] ?? 'Unnamed'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteCard(card[DatabaseHelper.columnId]),
                  ),
                );
              },
            ),
    );
  }
}