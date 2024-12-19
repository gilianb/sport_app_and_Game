import 'package:flutter/material.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, required this.title});

  final String title;

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
            Tab(text: "Global Statistics "),
          ],
          labelColor: Colors.white, // Color for selected tab text
          unselectedLabelColor:
              Colors.grey[400], // Color for unselected tab text
          indicatorColor: Colors.orangeAccent, // Indicator color for active tab
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/statistics_background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent overlay
          Container(
            color: Colors.black.withOpacity(0.6),
          ),
          // Tab View
          TabBarView(
            controller: _tabController,
            children: [
              PersonalStatisticsTab(),
              GlobalStatisticsTab(),
            ],
          ),
        ],
      ),
    );
  }
}

class PersonalStatisticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'My Statistics',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          // Tableau des statistiques personnelles
          Expanded(
            child: ListView(
              children: [
                _buildStatRow("Number of trainig", "15"),
                _buildStatRow("Total distance", "45 km"),
                _buildStatRow("Total time", "10 h"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Placeholder pour le graphique
          SizedBox(
            height: 200,
            child: Container(
              color: Colors.blueGrey,
              child: const Center(
                child: Text(
                  'Graph here',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class GlobalStatisticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Global Statistics',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildStatRow("total number of users", "120"),
                _buildStatRow("total Distance", "4500 km"),
                _buildStatRow("Total time", "1000 h"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
