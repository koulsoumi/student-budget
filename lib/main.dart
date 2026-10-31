
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
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
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: const Color(0xFFF4F7F6),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF4F7F6),
    foregroundColor: Color(0xFF12372A),
    elevation: 0,
    centerTitle: false,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 1,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    margin: const EdgeInsets.symmetric(
      vertical: 6,
      horizontal: 0,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF4F7F6),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
  ),
),

      home: const HomePage(),
    );
  }
}


class Operation {
  final String description;
  final double montant;
  final String categorie;
  final DateTime date;


  Operation({
    required this.description,
    required this.montant,
    required this.categorie,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Operation> revenus = [];
  DateTime moisSelectionne = DateTime.now();
  List<Operation> get revenusDuMois =>
    operationsDuMois(
      revenus,
      moisSelectionne.year,
      moisSelectionne.month,
    );

List<Operation> get depensesDuMois =>
    operationsDuMois(
      depenses,
      moisSelectionne.year,
      moisSelectionne.month,
    );
  final List<Operation> depenses = [];
  
final List<String> categories = [
  'Alimentation',
  'Transport',
  'Études',
  'Santé',
  'Vêtements',
  'Autre',
];

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

  for (final depense in depensesDuMois) {
    totalDepenses += depense.montant;
  }

  return budgetMensuel - totalDepenses;
}

double get pourcentageBudgetUtilise {
  if (budgetMensuel <= 0) return 1.0;

  double totalDepenses = 0;

  for (final depense in depensesDuMois) {
    totalDepenses += depense.montant;
  }

  return (totalDepenses / budgetMensuel).clamp(0.0, 1.0);
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
    return '${op.description}|${op.montant}|${op.categorie}|${op.date.toIso8601String()}';
  }).toList();

  final listeDepenses = depenses.map((op) {
    return '${op.description}|${op.montant}|${op.categorie}|${op.date.toIso8601String()}';
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

  final objectifEnregistre = prefs.getDouble('objectifEpargne');
  if (objectifEnregistre != null) {
    objectifEpargne = objectifEnregistre;
  }

  final listeRevenus = prefs.getStringList('revenus') ?? [];
  final listeDepenses = prefs.getStringList('depenses') ?? [];

  List<Operation> convertirOperations(List<String> lignes) {
    final operations = <Operation>[];

    for (final ligne in lignes) {
      final parties = ligne.split('|');

      if (parties.length >= 2) {
        final description = parties[0];
        final montant = double.tryParse(parties[1]);
        final categorie =
            parties.length >= 3 ? parties[2] : 'Autre';

        DateTime? date;
        if (parties.length >= 4) {
          date = DateTime.tryParse(parties[3]);
        }

        if (montant != null) {
          operations.add(
            Operation(
              description: description,
              montant: montant,
              categorie: categorie,
              date: date,
            ),
          );
        }
      }
    }

    return operations;
  }

  setState(() {
    revenus
      ..clear()
      ..addAll(convertirOperations(listeRevenus));

    depenses
      ..clear()
      ..addAll(convertirOperations(listeDepenses));
  });
}


  final TextEditingController descriptionController =
      TextEditingController();
  final TextEditingController montantController =
      TextEditingController();
  String categorieAjout = 'Autre';   
   

  
List<Operation> operationsDuMois(
  List<Operation> operations,
  int annee,
  int mois,
) {
  return operations.where((operation) {
    return operation.date.year == annee &&
        operation.date.month == mois;
  }).toList();
}

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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                value: 'Autre',
                items: categories.map((categorie) {
                  return DropdownMenuItem<String>(
                    value: categorie,
                    child: Text(categorie),
                  );
                }).toList(),
                onChanged: (valeur) {
  if (valeur != null) {
    
  }
},
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
  categorie: categorieAjout,
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

Builder(
  builder: (context) {
    final totalDepenses = depenses.fold<double>(
      0,
      (total, operation) => total + operation.montant,
    );

    final progression = budgetMensuel > 0
        ? (totalDepenses / budgetMensuel).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progression,
          minHeight: 10,
          borderRadius: BorderRadius.circular(10),
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            totalDepenses > budgetMensuel
                ? Colors.red
                : const Color(0xFF087F5B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(budgetMensuel > 0 ? totalDepenses / budgetMensuel * 100 : 0).toStringAsFixed(0)} % dépensé',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  },
),

const SizedBox(height: 12),
      
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

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      'Budget utilisé',
      style: TextStyle(
        fontSize: 13,
        color: Colors.black54,
      ),
    ),
    Text(
      '${(pourcentageBudgetUtilise * 100).round()} %',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: budgetRestant < 0
            ? Colors.red
            : const Color(0xFF087F5B),
      ),
    ),
  ],
),

const SizedBox(height: 8),

ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: LinearProgressIndicator(
    value: pourcentageBudgetUtilise,
    minHeight: 10,
    backgroundColor: const Color(0xFFE6ECE9),
    valueColor: AlwaysStoppedAnimation<Color>(
      budgetRestant < 0
          ? Colors.red
          : pourcentageBudgetUtilise >= 0.8
              ? Colors.orange
              : const Color(0xFF087F5B),
    ),
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
    gradient: const LinearGradient(
      colors: [
        Color(0xFF087F5B),
        Color(0xFF065F46),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF087F5B).withValues(alpha: 0.20),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Mon solde disponible',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
          ),
          const Icon(
            Icons.verified_user_outlined,
            color: Colors.white70,
            size: 22,
          ),
        ],
      ),
      const SizedBox(height: 24),
      Text(
        formatMontant(solde),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Revenus moins dépenses',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 13,
        ),
      ),
      const SizedBox(height: 18),
      Container(
        height: 4,
        width: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
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
    color: Color(0xFF12372A),
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
            
            const Text(
              'Dépenses par catégorie',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
if (calculerDepensesParCategorie().isNotEmpty) ...[
  SizedBox(
    height: 220,
    child: PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 40,
        sections: calculerDepensesParCategorie()
            .entries
            .map((entree) {
          return PieChartSectionData(
            color: Colors.green,
            value: entree.value,
            title: entree.key,
            radius: 65,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          );
        }).toList(),
      ),
    ),
  ),
  const SizedBox(height: 12),
],


            if (calculerDepensesParCategorie().isEmpty)
              const Text('Aucune dépense enregistrée.')
            else
              ...calculerDepensesParCategorie().entries.map((entree) {
                return Card(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(entree.key),
                    trailing: Text(
                      '${formatMontant(entree.value)} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF087F5B),
                      ),
                    ),
                  ),
                );
              }),

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


Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    IconButton(
      onPressed: () {
        setState(() {
          moisSelectionne = DateTime(
            moisSelectionne.year,
            moisSelectionne.month - 1,
          );
        });
      },
      icon: const Icon(Icons.chevron_left),
    ),
    Text(
      '${moisSelectionne.month.toString().padLeft(2, '0')}/${moisSelectionne.year}',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    IconButton(
      onPressed: () {
        setState(() {
          moisSelectionne = DateTime(
            moisSelectionne.year,
            moisSelectionne.month + 1,
          );
        });
      },
      icon: const Icon(Icons.chevron_right),
    ),
  ],
),
const SizedBox(height: 8),


            

if (revenusDuMois.isEmpty && depensesDuMois.isEmpty)
  const Card(
    color: Colors.white,
    child: ListTile(
      title: Text('Aucune opération pour ce mois.'),
      subtitle: Text('Ajoute un revenu ou une dépense.'),
    ),
  ),

...revenusDuMois.map(
  (op) => ligneOperation(
    op.description,
    op.montant,
    true,
    op.categorie,
  ),
),

...depensesDuMois.map(
  (op) => ligneOperation(
    op.description,
    op.montant,
    false,
    op.categorie,
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
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color(0xFFE6ECE9),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icone,
            color: couleur,
            size: 24,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          titre,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          montant,
          style: const TextStyle(
            color: Color(0xFF12372A),
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
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(
        color: Color(0xFFE6ECE9),
      ),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icone,
          color: couleur,
          size: 26,
        ),
      ),
      title: Text(
        titre,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Color(0xFF12372A),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          sousTitre,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: couleur,
      ),
      onTap: action,
    ),
  );
}


Future<void> modifierOperation(
  String description,
  double montant,
  bool estRevenu,
  String categorie,
) async {
  final descriptionController =
      TextEditingController(text: description);
  final montantController =
      TextEditingController(text: montant.toString());
  String categorieSelectionnee = categorie;

  final resultat = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Modifier une opération'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
              ),
              TextField(
                controller: montantController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant en FCFA',
                ),
              ),
              DropdownButtonFormField<String>(
                value: categorieSelectionnee,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (valeur) {
                  if (valeur != null) {
                    setDialogState(() {
                      categorieSelectionnee = valeur;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );

  if (resultat != true) {
    return;
  }

  final nouvelleDescription = descriptionController.text.trim();
  final nouveauMontant = double.tryParse(
    montantController.text.trim().replaceAll(',', '.'),
  );

if (!mounted) return;

if (nouvelleDescription.isEmpty ||
    nouveauMontant == null ||
    nouveauMontant <= 0) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Saisis une description et un montant valides.'),
    ),
  );
  return;
}

  final liste = estRevenu ? revenus : depenses;
  final index = liste.indexWhere(
    (operation) =>
        operation.description == description &&
        operation.montant == montant &&
        operation.categorie == categorie,
  );

  if (index == -1) return;

  setState(() {
    liste[index] = Operation(
      description: nouvelleDescription,
      montant: nouveauMontant,
      categorie: categorieSelectionnee,
    );
  });

  await sauvegarderDonnees();
}
  
void supprimerOperation(
  String description,
  double montant,
  bool estRevenu,
  String categorie,
) {
  setState(() {
    final liste = estRevenu ? revenus : depenses;

    liste.removeWhere(
      (operation) =>
          operation.description == description &&
          operation.montant == montant &&
          operation.categorie == categorie,
    );
  });

  sauvegarderDonnees();
}


  // Le reste de ta fonction reste inchangé.


Widget ligneOperation(
  String description,
  double montant,
  bool estRevenu,
  String categorie,
) {
  final couleur =
      estRevenu ? const Color(0xFF087F5B) : const Color(0xFFE05252);
  final signe = estRevenu ? '+' : '-';

  return Card(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.symmetric(vertical: 5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(
        color: Color(0xFFE6ECE9),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              estRevenu
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: couleur,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF12372A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  categorie,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            '$signe ${formatMontant(montant)}',
            maxLines: 1,
            style: TextStyle(
              color: couleur,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),

          const SizedBox(width: 2),

          PopupMenuButton<String>(
            tooltip: 'Actions',
            icon: const Icon(
              Icons.more_vert,
              color: Colors.black54,
            ),
            onSelected: (choix) async {
              if (choix == 'modifier') {
                modifierOperation(
                  description,
                  montant,
                  estRevenu,
                  categorie,
                );
              }

              if (choix == 'supprimer') {
                final confirmation = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text(
                      'Confirmer la suppression',
                    ),
                    content: Text(
                      'Veux-tu vraiment supprimer "$description" ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, true),
                        child: const Text(
                          'Supprimer',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmation == true) {
                  supprimerOperation(
                    description,
                    montant,
                    estRevenu,
                    categorie,
                  );
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'modifier',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Modifier'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'supprimer',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text('Supprimer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}



  Map<String, double> calculerDepensesParCategorie() {
    final Map<String, double> resultat = {};

    for (final depense in depenses) {
      resultat[depense.categorie] =
          (resultat[depense.categorie] ?? 0) + depense.montant;
    }

    return resultat;
  }

}
