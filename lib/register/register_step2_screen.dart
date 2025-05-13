import 'package:fitwithus/bottom_nav_screen.dart';
import 'package:flutter/material.dart';
import '../../services/firebase_register_service.dart';
import '../../utils/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          await Future.delayed(Duration(seconds: 5));
          await user.sendEmailVerification();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const BottomNavScreen(),
            ),
            (Route<dynamic> route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'too-many-requests') {
          message =
              "Too many registration attempts from this device. Please try again later.";
        } else {
          message = "Registration failed: ${e.message}";
        }
        setState(() {
          _errorMessage = message;
        });
      } catch (e) {
        setState(() {
          _errorMessage = "An unexpected error occurred: $e";
        });
      }
    }
  }

  bool _validateInputs() {
    final validationMessage = Validators.validateWeightHeightAndBirthDate(
      weightText: _weightController.text,
      heightText: _heightController.text,
      birthDate: _birthDate,
    );

    if (validationMessage != null) {
      setState(() {
        _errorMessage = validationMessage;
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
    return Theme(
        data: ThemeData.light(),
        child: Scaffold(
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
                      color: Colors.blueAccent,
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
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: InputDecoration(
                      labelText: "Select Gender",
                      labelStyle: const TextStyle(color: Colors.blueAccent),
                      prefixIcon:
                          const Icon(Icons.person_2, color: Colors.blueAccent),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 12),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blueAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.teal, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_drop_down_rounded,
                        color: Colors.blueAccent),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _selectBirthDate(context),
                      icon: const Icon(Icons.calendar_today,
                          color: Colors.blueAccent),
                      label: Text(
                        _birthDate == null
                            ? "Select Date of Birth"
                            : _birthDate!.toLocal().toString().split(' ')[0],
                        style: const TextStyle(
                            fontSize: 16, color: Colors.blueAccent),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        elevation: 0,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.blueAccent),
                        ),
                      ),
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
                        style:
                            TextStyle(fontSize: 18, color: Colors.blueAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
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
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: hintText,
        labelStyle: const TextStyle(color: Colors.blueAccent),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.teal, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
