import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ComplaintStatus {
  open('open', 'Open'),
  inProgress('in_progress', 'In progress'),
  resolved('resolved', 'Resolved');

  const ComplaintStatus(this.key, this.label);

  /// Value stored in Firestore.
  final String key;
  final String label;

  Color get color => switch (this) {
        ComplaintStatus.open => Colors.orange.shade800,
        ComplaintStatus.inProgress => Colors.blue.shade700,
        ComplaintStatus.resolved => Colors.green.shade700,
      };

  static ComplaintStatus fromKey(String? key) => ComplaintStatus.values
      .firstWhere((s) => s.key == key, orElse: () => ComplaintStatus.open);
}

const List<String> kComplaintCategories = [
  'Plumbing',
  'Electrical',
  'Lift',
  'Cleaning',
  'Parking',
  'Security',
  'Noise',
  'Other',
];

class Complaint {
  const Complaint({
    required this.id,
    required this.residentId,
    required this.residentName,
    required this.flat,
    required this.category,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.photoUrl,
  });

  final String id;
  final String residentId;
  final String residentName;
  final String flat;
  final String category;
  final String title;
  final String description;
  final ComplaintStatus status;
  final DateTime createdAt;
  final String? photoUrl;

  factory Complaint.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Complaint(
      id: doc.id,
      residentId: (d['residentId'] as String?) ?? '',
      residentName: (d['residentName'] as String?) ?? '',
      flat: (d['flat'] as String?) ?? '',
      category: (d['category'] as String?) ?? 'Other',
      title: (d['title'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      status: ComplaintStatus.fromKey(d['status'] as String?),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: d['photoUrl'] as String?,
    );
  }
}
