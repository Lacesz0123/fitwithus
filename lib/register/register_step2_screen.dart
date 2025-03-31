import 'package:flutter/material.dart';
import '../home_screen.dart';
import '../../services/firebase_register_service.dart';
import '../../utils/validators.dart';

class RegisterStep2Screen extends StatefulWidget {
  final String email;
  final String username;
  final String password;

  const RegisterStep2Screen({
    super.key,
    required this.email,
    required this.username,
    required this.password,
  });

  @override
  _RegisterStep2ScreenState createState() => _RegisterStep2ScreenState();
}

class _RegisterStep2ScreenState extends State<RegisterStep2Screen> {
  TextEditingController _weightController = TextEditingController();
  TextEditingController _heightController = TextEditingController();
  String _selectedGender = "Male";
  DateTime? _birthDate;
  String _errorMessage = '';

  Future<void> _registerUser() async {
    if (_validateInputs()) {
      try {
        final registerService = FirebaseRegisterService();
        final user = await registerService.registerUser(
          email: widget.email,
          password: widget.password,
          username: widget.username,
          weight: int.parse(_weightController.text),
          height: int.parse(_heightController.text),
          gender: _selectedGender,
          birthDate: _birthDate!,
        );

        if (user != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        print("Error during registration: $e");
        setState(() {
          _errorMessage = "An error occurred during registration.";
        });
      }
    }
  }

  bool _validateInputs() {
    if (_weightController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _birthDate == null) {
      setState(() {
        _errorMessage = 'All fields are required.';
      });
      return false;
    }

    if (!Validators.isWeightValid(_weightController.text)) {
      setState(() {
        _errorMessage = 'Weight must be a positive number and max 3 digits.';
      });
      return false;
    }

    if (!Validators.isHeightValid(_heightController.text)) {
      setState(() {
        _errorMessage = 'Height must be between 60 and 250 cm.';
      });
      return false;
    }

    return true;
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Additional Information'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Complete Your Profile",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please enter additional information to finish setting up your account.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              const Text("Gender"),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _weightController,
                hintText: "Your Weight (kg)",
                icon: Icons.fitness_center,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _heightController,
                hintText: "Your Height (cm)",
                icon: Icons.height,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text("Date of Birth"),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _selectBirthDate(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.teal,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.teal),
                  ),
                ),
                child: Text(
                  _birthDate == null
                      ? "Select Date of Birth"
                      : _birthDate!.toLocal().toString().split(' ')[0],
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _registerUser,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Register",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.teal),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
