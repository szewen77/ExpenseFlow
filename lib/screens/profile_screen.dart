import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../models/profile.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _goalNameController = TextEditingController();
  final _goalAmountController = TextEditingController();
  final _avatars = ['🙂', '😎', '🤩', '🧠', '🚀', '🐼', '🦄', '🐯'];
  String _selectedAvatar = '🙂';
  Goal? _goal;
  DateTime _goalStart = DateTime.now();
  DateTime _goalEnd = DateTime.now().add(const Duration(days: 30));
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profileFuture = DatabaseService.instance.getUserProfile();
    final goalFuture = DatabaseService.instance.getGoal();
    final profile = await profileFuture;
    final goal = await goalFuture;
    if (!mounted) return;
    setState(() {
      _nameController.text = profile.name;
      _selectedAvatar = profile.avatarEmoji;
      _goal = goal;
      if (goal != null) {
        _goalNameController.text = goal.name;
        _goalAmountController.text = goal.targetAmount.toStringAsFixed(2);
        _goalStart = goal.startDate;
        _goalEnd = goal.endDate;
      } else {
        _goalNameController.clear();
        _goalAmountController.clear();
        _goalStart = DateTime.now();
        _goalEnd = DateTime.now().add(const Duration(days: 30));
      }
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }
    final profile = UserProfile(
      id: 1,
      name: name,
      avatarEmoji: _selectedAvatar,
    );
    await DatabaseService.instance.upsertUserProfile(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  Future<void> _saveGoal() async {
    final name = _goalNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a goal name')));
      return;
    }

    final amount = double.tryParse(_goalAmountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid target amount')),
      );
      return;
    }

    if (_goalEnd.isBefore(_goalStart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    final goal = Goal(
      id: _goal?.id,
      name: name,
      targetAmount: amount,
      startDate: _goalStart,
      endDate: _goalEnd,
    );

    await DatabaseService.instance.upsertGoal(goal);
    if (!mounted) return;
    setState(() => _goal = goal);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saving goal updated')));
  }

  Future<void> _clearGoal() async {
    await DatabaseService.instance.deleteGoal();
    if (!mounted) return;
    setState(() {
      _goal = null;
      _goalNameController.clear();
      _goalAmountController.clear();
      _goalStart = DateTime.now();
      _goalEnd = DateTime.now().add(const Duration(days: 30));
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saving goal removed')));
  }

  Future<void> _pickGoalStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _goalStart,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _goalStart = picked);
      if (_goalEnd.isBefore(picked)) {
        setState(() => _goalEnd = picked.add(const Duration(days: 30)));
      }
    }
  }

  Future<void> _pickGoalEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _goalEnd.isBefore(_goalStart) ? _goalStart : _goalEnd,
      firstDate: _goalStart,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _goalEnd = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Security')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  Text(
                    'Personal Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter your name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pick an avatar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: _avatars.map((emoji) {
                      final isSelected = emoji == _selectedAvatar;
                      return ChoiceChip(
                        label: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedAvatar = emoji);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saveProfile,
                    child: const Text('Save Profile'),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Saving Goal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _goalNameController,
                            decoration: const InputDecoration(
                              labelText: 'Goal name',
                              hintText: 'E.g. Save for trip',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _goalAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Target amount (RM)',
                              hintText: '0.00',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickGoalStartDate,
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(
                                    'Start ${formatDate(_goalStart)}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickGoalEndDate,
                                  icon: const Icon(Icons.event),
                                  label: Text('End ${formatDate(_goalEnd)}'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: _saveGoal,
                                  child: const Text('Save Goal'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (_goal != null)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _clearGoal,
                                    child: const Text('Remove Goal'),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalNameController.dispose();
    _goalAmountController.dispose();
    super.dispose();
  }
}
