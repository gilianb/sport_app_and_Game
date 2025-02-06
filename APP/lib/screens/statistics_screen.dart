import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, required this.title, required this.id});
  final String title;
  final String? id;

  @override
  State<StatisticsPage> createState() => StatisticsPageState();
}

class StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 15, 91, 124),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "My Statistics"),
            Tab(text: "Global Statistics"),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: Colors.orangeAccent,
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/statistics_background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.6),
          ),
          TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: UserPerformanceStatistics(userId: widget.id),
              ),
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: AllUsersStatistics(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AllUsersStatistics extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _fetchAllUsersData() async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    final querySnapshot = await usersCollection.get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      final performanceHistory =
          List<Map<String, dynamic>>.from(data['performanceHistory'] ?? []);
      final totalDistance = performanceHistory
          .map((e) => double.tryParse(e['distance'].toString()) ?? 0.0)
          .fold(0.0, (sum, element) => sum + element);

      final totalTime = performanceHistory
          .map((e) => double.tryParse(e['time'].toString()) ?? 0.0)
          .fold(0.0, (sum, element) => sum + element);

      return {
        'username': data['username'] ?? 'Unknown',
        'totalDistance': totalDistance,
        'totalTime': totalTime,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllUsersData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Erreur : ${snapshot.error}"));
        } else if (snapshot.hasData) {
          final usersData = snapshot.data!;
          return _buildTable(usersData);
        } else {
          return const Center(child: Text("Aucune donnée disponible."));
        }
      },
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> usersData) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'All Users Statistics',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(
                  label: Text('Username',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Total Distance (km)',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Total Time (h)',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ],
              rows: usersData.map((user) {
                return DataRow(cells: [
                  DataCell(Text(user['username'],
                      style: const TextStyle(color: Colors.white70))),
                  DataCell(Text(user['totalDistance'].toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white70))),
                  DataCell(Text(user['totalTime'].toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white70))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class UserPerformanceStatistics extends StatelessWidget {
  final String? userId;

  const UserPerformanceStatistics({super.key, required this.userId});

  Future<List<Map<String, dynamic>>> _fetchUserData() async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw Exception("No user found.");
    }

    final data = userDoc.data();
    final performanceHistory =
        List<Map<String, dynamic>>.from(data?['performanceHistory'] ?? []);

    return performanceHistory.map((performance) {
      return {
        'date': performance['date'] ?? 'Unknown Date',
        'distance': double.tryParse(performance['distance'].toString()) ?? 0.0,
        'time': double.tryParse(performance['time'].toString()) ?? 0.0,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Erreur : ${snapshot.error}"));
        } else if (snapshot.hasData) {
          final performanceData = snapshot.data!;
          return _buildTable(performanceData);
        } else {
          return const Center(child: Text("Aucune donnée disponible."));
        }
      },
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> performanceData) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'User Performance Statistics',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(
                  label: Text('Date',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Distance (km)',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                DataColumn(
                  label: Text('Time (sec)',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ],
              rows: performanceData.map((performance) {
                return DataRow(cells: [
                  DataCell(Text(performance['date'],
                      style: const TextStyle(color: Colors.white70))),
                  DataCell(Text(performance['distance'].toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white70))),
                  DataCell(Text(performance['time'].toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white70))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
