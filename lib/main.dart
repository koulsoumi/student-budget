
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const StudentBudgetApp());
}

class StudentBudgetApp extends StatelessWidget {
  const StudentBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudentBudget',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087F5B),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class Operation {
  final String description;
  final double montant;

  Operation({
    required this.description,
    required this.montant,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Operation> revenus = [];
  final List<Operation> depenses = [];
  double budgetMensuel = 50000;
  double objectifEpargne = 100000;
  
double get montantEpargne {
  double totalRevenus = 0;
  double totalDepenses = 0;

  for (final revenu in revenus) {
    totalRevenus += revenu.montant;
  }

  for (final depense in depenses) {
    totalDepenses += depense.montant;
  }

  final resultat = totalRevenus - totalDepenses;
  return resultat > 0 ? resultat : 0;
}
double get epargneRestante {
  final reste = objectifEpargne - montantEpargne;
  return reste > 0 ? reste : 0;
}

  double get budgetRestant {
  double totalDepenses = 0;

  for (final depense in depenses) {
    totalDepenses += depense.montant;
  }

  return budgetMensuel - totalDepenses;
}
  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }
  Future<void> sauvegarderDonnees() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('budgetMensuel', budgetMensuel);
  await prefs.setDouble('objectifEpargne', objectifEpargne);

  final listeRevenus = revenus.map((op) {
    return '${op.description}|${op.montant}';
  }).toList();

  final listeDepenses = depenses.map((op) {
    return '${op.description}|${op.montant}';
  }).toList();

  await prefs.setStringList('revenus', listeRevenus);
  await prefs.setStringList('depenses', listeDepenses);
}

Future<void> chargerDonnees() async {
  final prefs = await SharedPreferences.getInstance();
  final budgetEnregistre = prefs.getDouble('budgetMensuel');

if (budgetEnregistre != null) {
  budgetMensuel = budgetEnregistre;
}

  final listeRevenus = prefs.getStringList('revenus') ?? [];
  final listeDepenses = prefs.getStringList('depenses') ?? [];

  setState(() {
    revenus.clear();
    depenses.clear();

    for (final ligne in listeRevenus) {
      final separateur = ligne.lastIndexOf('|');

      if (separateur != -1) {
        final description = ligne.substring(0, separateur);
        final montant = double.tryParse(
          ligne.substring(separateur + 1),
        );

        if (montant != null) {
          revenus.add(
            Operation(description: description, montant: montant),
          );
        }
      }
    }

    for (final ligne in listeDepenses) {
      final separateur = ligne.lastIndexOf('|');

      if (separateur != -1) {
        final description = ligne.substring(0, separateur);
        final montant = double.tryParse(
          ligne.substring(separateur + 1),
        );

        if (montant != null) {
          depenses.add(
            Operation(description: description, montant: montant),
          );
        }
      }
    }
  });
  final objectifEnregistre = prefs.getDouble('objectifEpargne');

if (objectifEnregistre != null) {
  objectifEpargne = objectifEnregistre;
}
}


  final TextEditingController descriptionController =
      TextEditingController();
  final TextEditingController montantController =
      TextEditingController();

  double get totalRevenus =>
      revenus.fold(0, (total, op) => total + op.montant);

  double get totalDepenses =>
      depenses.fold(0, (total, op) => total + op.montant);

  double get solde => totalRevenus - totalDepenses;

  String formatMontant(double montant) {
    return '${montant.toStringAsFixed(0)} FCFA';
  }

  void ouvrirFormulaire(bool estRevenu) {
    descriptionController.clear();
    montantController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            estRevenu ? 'Ajouter un revenu' : 'Ajouter une dépense',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Ex. : Transport',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: montantController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Montant en FCFA',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final description =
                    descriptionController.text.trim();
                final montant = double.tryParse(
                  montantController.text.trim().replaceAll(',', '.'),
                );

                if (description.isEmpty ||
                    montant == null ||
                    montant <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Saisis une description et un montant valide.',
                      ),
                    ),
                  );
                  return;
                }

                setState(() {
  final operation = Operation(
    description: description,
    montant: montant,
  );

  if (estRevenu) {
    revenus.add(operation);
  } else {
    depenses.add(operation);
  }
});

sauvegarderDonnees();

                Navigator.pop(dialogContext);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    montantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text(
          'StudentBudget',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF087F5B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bonjour ! 👋',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text('Gère ton argent simplement.'),
            const SizedBox(height: 24),
            
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: const Color(0xFF087F5B),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Mon budget mensuel',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        formatMontant(budgetMensuel),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF087F5B),
        ),
      ),
      
const SizedBox(height: 12),

ElevatedButton.icon(
  onPressed: () {
    final controleur = TextEditingController(
      text: budgetMensuel.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier mon budget'),
          content: TextField(
            controller: controleur,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Budget mensuel en FCFA',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final nouveauBudget = double.tryParse(
                  controleur.text.trim(),
                );

                if (nouveauBudget != null && nouveauBudget > 0) {
                  
setState(() {
  budgetMensuel = nouveauBudget;
});

sauvegarderDonnees();

Navigator.pop(context);

                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  },
  icon: const Icon(Icons.edit),
  label: const Text('Modifier mon budget'),
),

      
      const SizedBox(height: 10),
Text(
  'Budget restant : ${formatMontant(budgetRestant)}',
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF087F5B),
  ),
),

const SizedBox(height: 12),
if (budgetRestant < 0)
  const Text(
    '⚠️ Attention ! Tu as dépassé ton budget mensuel.',
    style: TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.bold,
      fontSize: 15,
    ),
  )
else
  const Text(
    'Tu respectes ton budget !',
    style: TextStyle(
      color: Color(0xFF087F5B),
      fontWeight: FontWeight.w500,
      fontSize: 14,
    ),
  ),

    ],
  ),
),
const SizedBox(height: 16),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: const Color(0xFF087F5B),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '🎯 Mon objectif d’épargne',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Objectif : ${formatMontant(objectifEpargne)}',
      ),
      const SizedBox(height: 8),
      Text(
        'Déjà disponible : ${formatMontant(montantEpargne)}',
      ),
      const SizedBox(height: 8),
      Text(
        'Reste à économiser : ${formatMontant(epargneRestante)}',
        style: const TextStyle(
          color: Color(0xFF087F5B),
          fontWeight: FontWeight.bold,
        ),
      ),
      

const SizedBox(height: 16),
ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: LinearProgressIndicator(
    value: objectifEpargne > 0
        ? (montantEpargne / objectifEpargne).clamp(0.0, 1.0)
        : 0.0,
    minHeight: 12,
    backgroundColor: Colors.grey.shade200,
    valueColor: const AlwaysStoppedAnimation<Color>(
      Color(0xFF087F5B),
    ),
  ),
),
const SizedBox(height: 8),
Text(
  '${objectifEpargne > 0 ? ((montantEpargne / objectifEpargne).clamp(0.0, 1.0) * 100).toStringAsFixed(0) : 0} % atteint',
  style: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Color(0xFF087F5B),
  ),
),
const SizedBox(height: 12),
ElevatedButton.icon(

  onPressed: () {
    final controleur = TextEditingController(
      text: objectifEpargne.toStringAsFixed(0),
    );
    

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          
          title: const Text('Modifier mon objectif'),
          content: TextField(
            controller: controleur,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Montant en FCFA',
              hintText: 'Exemple : 100000',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final montant = double.tryParse(
                  controleur.text.trim(),
                );

                if (montant != null && montant > 0) {
                  setState(() {
                    objectifEpargne = montant;
                  });
                  sauvegarderDonnees();
                  Navigator.pop(context);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  },
  icon: const Icon(Icons.edit),
  
  label: const Text('Modifier mon objectif'),
),

    ],
  ),
),
const SizedBox(height: 16),



            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF087F5B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mon solde disponible',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    formatMontant(solde),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Revenus moins dépenses',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Résumé du mois',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: carteResume(
                    'Revenus',
                    formatMontant(totalRevenus),
                    Icons.trending_up,
                    const Color(0xFF087F5B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: carteResume(
                    'Dépenses',
                    formatMontant(totalDepenses),
                    Icons.trending_down,
                    Colors.redAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),
            const Text(
              'Mes opérations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            carteAction(
              'Ajouter un revenu',
              'Enregistrer l’argent reçu',
              Icons.add_circle_outline,
              const Color(0xFF087F5B),
              () => ouvrirFormulaire(true),
            ),
            carteAction(
              'Ajouter une dépense',
              'Transport, alimentation, inscription...',
              Icons.remove_circle_outline,
              Colors.redAccent,
              () => ouvrirFormulaire(false),
            ),

            const SizedBox(height: 24),
            const Text(
              'Historique des opérations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (revenus.isEmpty && depenses.isEmpty)
              const Card(
                color: Colors.white,
                child: ListTile(
                  title: Text('Aucune opération enregistrée.'),
                  subtitle: Text('Ajoute ton premier revenu ou dépense.'),
                ),
              ),

            ...revenus.map(
              (op) => ligneOperation(
                op.description,
                op.montant,
                true,
              ),
            ),
            ...depenses.map(
              (op) => ligneOperation(
                op.description,
                op.montant,
                false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget carteResume(
    String titre,
    String montant,
    IconData icone,
    Color couleur,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: couleur, size: 28),
          const SizedBox(height: 10),
          Text(titre, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            montant,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget carteAction(
    String titre,
    String sousTitre,
    IconData icone,
    Color couleur,
    VoidCallback action,
  ) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icone, color: couleur, size: 30),
        title: Text(
          titre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(sousTitre),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: action,
      ),
    );
  }

  Widget ligneOperation(
    String description,
    double montant,
    bool estRevenu,
  ) {
    final couleur =
        estRevenu ? const Color(0xFF087F5B) : Colors.redAccent;
    final signe = estRevenu ? '+' : '-';

    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Icon(
          estRevenu ? Icons.arrow_downward : Icons.arrow_upward,
          color: couleur,
        ),
        title: Text(description),
        trailing: Text(
          '$signe ${formatMontant(montant)}',
          style: TextStyle(
            color: couleur,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
