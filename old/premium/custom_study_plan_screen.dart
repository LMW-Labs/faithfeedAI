import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CustomStudyPlanScreen extends StatefulWidget {
  const CustomStudyPlanScreen({super.key});

  @override
  State<CustomStudyPlanScreen> createState() => _CustomStudyPlanScreenState();
}

class _CustomStudyPlanScreenState extends State<CustomStudyPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _booksController = TextEditingController();
  double _daysPerWeek = 3;
  bool _isLoading = false;

  @override
  void dispose() {
    _topicController.dispose();
    _booksController.dispose();
    super.dispose();
  }

  void _generatePlan() {
    if (_formKey.currentState!.validate()) {
      // TODO: Connect to backend to generate the plan
      setState(() => _isLoading = true);

      // For now, simulate a network call and show a confirmation
      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your study plan is being generated! (Backend not connected)'),
              backgroundColor: AppTheme.primaryTeal,
            ),
          );
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Create Study Plan'),
        backgroundColor: AppTheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _topicController,
              label: 'What topic are you interested in?',
              hint: 'e.g., Forgiveness, Leadership, Faith...',
              icon: Icons.lightbulb_outline,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _booksController,
              label: 'Any specific books or chapters?',
              hint: 'e.g., Proverbs, John 1-3...',
              icon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: 24),
            _buildSlider(),
            const SizedBox(height: 40),
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_stories_outlined, size: 40, color: AppTheme.primaryTeal),
        const SizedBox(height: 12),
        Text(
          'Personalized Bible Study Plan',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tell us your goals, and our AI will create a custom reading plan just for you.',
          style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.onSurfaceVariant),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          // Optional validation
          validator: (value) {
            if (controller == _topicController && (value == null || value.isEmpty)) {
              return 'Please enter a topic to focus on.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How many days per week?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.date_range_outlined, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: _daysPerWeek,
                  min: 1,
                  max: 7,
                  divisions: 6,
                  label: _daysPerWeek.round().toString(),
                  activeColor: AppTheme.primaryTeal,
                  inactiveColor: AppTheme.darkGrey,
                  onChanged: (value) {
                    setState(() {
                      _daysPerWeek = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _daysPerWeek.round().toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ElevatedButton.icon(
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text('Generate My Plan', style: TextStyle(color: Colors.white, fontSize: 18)),
            onPressed: _generatePlan,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: AppTheme.primaryTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
  }
}
