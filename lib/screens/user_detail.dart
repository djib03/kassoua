import 'package:flutter/material.dart';

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({Key? key}) : super(key: key);

  Widget _buildInfoRow({Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('ID:', style: TextStyle(fontSize: 16)),
          Text(
            '12345',
            style: TextStyle(fontSize: 16, color: valueColor ?? Colors.black),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Details')),
      body: Center(child: Text('Details for user:')),
    );
  }
}
