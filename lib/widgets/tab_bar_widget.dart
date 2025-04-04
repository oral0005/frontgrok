import 'package:flutter/material.dart';

class TabBarWidget extends StatefulWidget {
  final String firstTab;
  final String secondTab;
  final ValueChanged<int> onTabChanged;

  const TabBarWidget({
    required this.firstTab,
    required this.secondTab,
    required this.onTabChanged,
    super.key,
  });

  @override
  _TabBarWidgetState createState() => _TabBarWidgetState();
}

class _TabBarWidgetState extends State<TabBarWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        widget.onTabChanged(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.red,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.red,
          tabs: [
            Tab(text: widget.firstTab),
            Tab(text: widget.secondTab),
          ],
        ),
      ],
    );
  }
}