import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sentinela_app_pos_simulator/routes/navigation_service.dart';
import 'package:sentinela_app_pos_simulator/src/pages/loading/loading_controller.dart';

class UserSerialForm extends StatefulWidget {
  final LoadingController controller;
  const UserSerialForm({super.key, required this.controller});

  @override
  State<UserSerialForm> createState() => _UserSerialFormState();
}

class _UserSerialFormState extends State<UserSerialForm> {
  final _formKey = GlobalKey<FormState>();
  String? _inputValue; // change it for the textcontroller of this form
  final ValueNotifier<String> _errorMessage = ValueNotifier('');
  bool _isSubmitting = false;

  void _submitFormDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(200),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.teal,
          contentPadding: EdgeInsets.all(12),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircularProgressIndicator(color: Colors.tealAccent),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  "Validando Chave...",
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm(String? value) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    FocusScope.of(context).unfocus();
    _inputValue = value;
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _submitFormDialog(context);
      String? validationMessage = await widget.controller.findSerialGetSchema(_inputValue!);
      if (validationMessage != null) {
        _errorMessage.value = validationMessage;
      }
      _isSubmitting = false;
      GetIt.I<NavigationService>().pop();
      return;
    }
    _isSubmitting = false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Bloqueia completamente a tentativa de voltar
        debugPrint("Voltar bloqueado. didPop: $didPop, result: $result");
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Vamos Registrar a Sentinela', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white)),
            Text('Insira sua chave', style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.white70)),
            ValueListenableBuilder(
              // error message text widget
              valueListenable: _errorMessage,
              builder: (context, value, child) {
                return Text(
                  value.toString(),
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                );
              },
            ),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.tealAccent,
                      border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(24)),
                      prefixIcon: Icon(Icons.key, color: Colors.teal.shade900),
                      errorStyle: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.red.shade300, fontWeight: FontWeight.bold),
                    ),
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.teal.shade900),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        _errorMessage.value = 'Campo vazio';
                        return 'Insira sua chave';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _errorMessage.value = '';
                      _inputValue = value;
                    },
                    onSaved: (value) {
                      widget.controller.userSerialFormField.text = value!;
                      _inputValue = value;
                    },
                    onFieldSubmitted: (value) {
                      _submitForm(_inputValue);
                    },
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      _submitForm(_inputValue);
                    },
                    style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.tealAccent.shade400)),
                    child: Text('Confirmar', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.teal.shade900)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
