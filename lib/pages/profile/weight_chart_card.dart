import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Egy statikus widget, amely egy BarChart (oszlopdiagram) segítségével mutatja a felhasználó súlyváltozását időrendben.
///
/// Fő funkciók:
/// - Lekérdezi az aktuális felhasználó `weights/{uid}/entries` kollekcióját időrendben.
/// - Minden adatpontot egy oszlopként jelenít meg, a súly (`weight`) értékével.
/// - Világos és sötét témához igazodik a színvilág.
///
/// Megjegyzés:
/// - Ha nincs adat, egy "No weight data available" üzenet jelenik meg.
/// - Az oszlopok rögzített maximális magasságig (`maxY: 200`) skálázódnak.
class WeightChartCard extends StatelessWidget {
  const WeightChartCard({super.key});

  /// A bejelentkezett felhasználó súlybejegyzéseit adja vissza stream formájában.
  ///
  /// Visszatérési érték:
  /// - `Stream<List<Map<String, dynamic>>>`, amely minden bejegyzést egy Map-ként tartalmaz (`weight`, `date` mezőkkel).
  ///
  /// A lekérdezés `orderBy('date', ascending)` sorrendben hozza az adatokat.
  Stream<List<Map<String, dynamic>>> _getWeightEntries() {
    final user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('weights')
        .doc(user?.uid)
        .collection('entries')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.blueAccent;
    final containerColor = isDark ? Colors.grey.shade900 : Colors.white;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight Change Over Time',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getWeightEntries(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No weight data available',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  );
                }

                final entries = snapshot.data!;

                return SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: 200,
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 20,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()} kg',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        horizontalInterval: 20,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(
                        entries.length,
                        (index) {
                          final entry = entries[index];
                          final weight = (entry['weight'] as num).toDouble();
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: weight,
                                width: 16,
                                borderRadius: BorderRadius.circular(6),
                                color: Colors.blueAccent.withOpacity(0.8),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 0,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.shade200,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
