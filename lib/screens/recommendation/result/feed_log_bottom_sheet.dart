import 'package:flutter/material.dart';

class FeedLogBottomSheet extends StatelessWidget {
  const FeedLogBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Catatan Pemberian Pakan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text('Log Feeding Form (Skeleton)'),
        ],
      ),
    );
  }
}
