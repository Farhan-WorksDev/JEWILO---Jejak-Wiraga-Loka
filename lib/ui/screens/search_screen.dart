import 'package:flutter/material.dart';
import '../theme.dart';
import 'tarian_search_tab.dart';
import 'sanggar_search_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text('Cari',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18)),
              ),
            ]),
          ),
          // TabBar
          TabBar(
            controller: _ctrl,
            labelColor: C.purple,
            unselectedLabelColor: C.muted,
            indicatorColor: C.purple,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 13.5),
            tabs: const [
              Tab(text: 'Tarian', icon: Icon(Icons.menu_book, size: 18)),
              Tab(text: 'Sanggar', icon: Icon(Icons.home_work, size: 18)),
            ],
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _ctrl,
              children: const [
                TarianTab(),
                SanggarSearchScreen(),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}