import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/counsellor_model.dart';
import '../../services/support_request_service.dart';

class CounsellorDetailScreen extends StatefulWidget {
  final CounsellorModel counsellor;

  const CounsellorDetailScreen({super.key, required this.counsellor});

  @override
  State<CounsellorDetailScreen> createState() => _CounsellorDetailScreenState();
}

class _CounsellorDetailScreenState extends State<CounsellorDetailScreen> {
  final SupportRequestService _supportRequestService = SupportRequestService();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasPendingRequest = false;
  bool _isCheckingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkPendingRequest();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkPendingRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final hasPending = await _supportRequestService.hasPendingSupportRequest(
        user.uid,
      );
      setState(() {
        _hasPendingRequest = hasPending;
        _isCheckingStatus = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  String _getStatusText(CounsellorStatus status) {
    switch (status) {
      case CounsellorStatus.available:
        return 'Available';
      case CounsellorStatus.busy:
        return 'Busy';
      case CounsellorStatus.offline:
        return 'Offline';
    }
  }

  Color _getStatusColor(CounsellorStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case CounsellorStatus.available:
        return colorScheme.tertiary;
      case CounsellorStatus.busy:
        return colorScheme.secondary;
      case CounsellorStatus.offline:
        return colorScheme.onSurfaceVariant;
    }
  }

  Future<void> _submitSupportRequest() async {
    final colorScheme = Theme.of(context).colorScheme;

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a message')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to request support')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _supportRequestService.createSupportRequest(
        userId: user.uid,
        counsellorId: widget.counsellor.id,
        message: _messageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support request submitted.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: ${e.toString()}'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Counsellor')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section with Profile
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: colorScheme.surfaceContainerLow),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: widget.counsellor.profileImageUrl != null
                        ? NetworkImage(widget.counsellor.profileImageUrl!)
                        : null,
                    child: widget.counsellor.profileImageUrl == null
                        ? Text(
                            widget.counsellor.name.isNotEmpty
                                ? widget.counsellor.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.counsellor.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.counsellor.specialization != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.counsellor.specialization!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        widget.counsellor.status,
                      ).withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(widget.counsellor.status),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _getStatusText(widget.counsellor.status),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusColor(widget.counsellor.status),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.counsellor.yearsOfExperience != null) ...[
                    _buildDetailItem(
                      icon: Icons.school,
                      title: 'Experience',
                      value: '${widget.counsellor.yearsOfExperience} years',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.counsellor.bio != null) ...[
                    _buildDetailItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      value: widget.counsellor.bio!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.counsellor.availableHours.isNotEmpty) ...[
                    _buildDetailItem(
                      icon: Icons.access_time,
                      title: 'Available Hours',
                      value: widget.counsellor.availableHours.join(', '),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildDetailItem(
                    icon: Icons.email,
                    title: 'Email',
                    value: widget.counsellor.email,
                  ),
                  const SizedBox(height: 32),

                  // Request Support Section
                  if (_isCheckingStatus)
                    const Center(child: CircularProgressIndicator())
                  else if (_hasPendingRequest)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You already have a pending support request. Please wait for a response.',
                              style: TextStyle(
                                color: colorScheme.onSecondaryContainer,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Support',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Describe your situation and how this counsellor can help you.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'Tell us how we can help...',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting
                                ? null
                                : _submitSupportRequest,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Submit request'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
