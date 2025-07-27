import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spazigo/services/api_service.dart';
import 'package:spazigo/widgets/custom_text_field.dart';

class AddContainerScreen extends StatefulWidget {
  const AddContainerScreen({super.key});

  @override
  State<AddContainerScreen> createState() => _AddContainerScreenState();
}

class _AddContainerScreenState extends State<AddContainerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _routesController = TextEditingController();
  final TextEditingController _spaceTotalController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _modalController = TextEditingController();

  DateTime? _bookingDeadline;
  DateTime? _departureTime;

  final List<String> _transportModes = ['road', 'rail', 'sea', 'air'];
  String? _selectedTransportMode;

  Future<void> _pickDateTime(BuildContext context, {required bool isDeparture}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          final selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (isDeparture) {
            _departureTime = selectedDateTime;
          } else {
            _bookingDeadline = selectedDateTime;
          }
        });
      }
    }
  }

  void _addContainer() async {
    if (_formKey.currentState!.validate()) {
      if (_bookingDeadline == null || _departureTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both booking deadline and departure time.')),
        );
        return;
      }
      if (_selectedTransportMode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a transport mode.')),
        );
        return;
      }
      if (_bookingDeadline!.isAfter(_departureTime!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking deadline must be before departure time.')),
        );
        return;
      }

      try {
        final containerData = {
          'origin': _originController.text,
          'destination': _destinationController.text,
          'routes': _routesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          'space_total': double.parse(_spaceTotalController.text),
          'price': double.parse(_priceController.text),
          'modal': _selectedTransportMode,
          'deadline': _bookingDeadline!.toIso8601String(),
          'departure_time': _departureTime!.toIso8601String(),
        };

        await ApiService.createContainer(containerData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Container added successfully!')),
        );
        context.pop(); // Go back to dashboard or container list
      } on ApiException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add container: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Select Date and Time';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Container'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  controller: _originController,
                  labelText: 'Origin Location',
                  validator: (value) => value!.isEmpty ? 'Enter origin' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _destinationController,
                  labelText: 'Destination Location',
                  validator: (value) => value!.isEmpty ? 'Enter destination' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _routesController,
                  labelText: 'Intermediate Routes (comma-separated, optional)',
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _spaceTotalController,
                  labelText: 'Total Space (units)',
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty || double.tryParse(value) == null || double.parse(value) <= 0
                      ? 'Enter valid positive space'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _priceController,
                  labelText: 'Price per Unit (₹)',
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty || double.tryParse(value) == null || double.parse(value) <= 0
                      ? 'Enter valid positive price'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTransportMode,
                  decoration: const InputDecoration(
                    labelText: 'Transport Mode',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Select Mode'),
                  items: _transportModes.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(mode.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTransportMode = value;
                    });
                  },
                  validator: (value) => value == null ? 'Please select transport mode' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text('Booking Deadline: ${_formatDateTime(_bookingDeadline)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDateTime(context, isDeparture: false),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text('Departure Time: ${_formatDateTime(_departureTime)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDateTime(context, isDeparture: true),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addContainer,
                    child: const Text('Add Container'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _routesController.dispose();
    _spaceTotalController.dispose();
    _priceController.dispose();
    _modalController.dispose();
    super.dispose();
  }
}
