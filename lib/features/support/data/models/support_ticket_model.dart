enum SupportTicketStatus { open, inProgress, resolved, closed }

class SupportTicketModel {
  const SupportTicketModel({
    required this.id,
    required this.subject,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String subject;
  final SupportTicketStatus status;
  final DateTime createdAt;
}
