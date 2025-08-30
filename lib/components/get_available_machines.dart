import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sentinela_app_pos_simulator/models/api_machines_available_model.dart';
import 'package:sentinela_app_pos_simulator/routes/navigation_service.dart';
import 'package:sentinela_app_pos_simulator/src/pages/loading/loading_controller.dart';
import 'package:sentinela_app_pos_simulator/utils/constants.dart';
import 'package:sentinela_app_pos_simulator/utils/utils.dart';

class GetAvailableMachinesForm extends StatefulWidget {
  final LoadingController controller;
  const GetAvailableMachinesForm({super.key, required this.controller});

  @override
  State<GetAvailableMachinesForm> createState() => _GetAvailableMachinesFormState();
}

class _GetAvailableMachinesFormState extends State<GetAvailableMachinesForm> {
  final _formKey = GlobalKey<FormState>();
  Key _futureKey = UniqueKey();
  final ValueNotifier<String> _errorMessage = ValueNotifier('');
  bool _isSubmitting = false;
  final ValueNotifier<Machines?> _selectedOption = ValueNotifier(null);

  void _submitFormDialog(BuildContext context) async {
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
                  "Registrando Sentinela...",
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

  Future<void> _submitForm(Machines? value) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    FocusScope.of(context).unfocus();
    _selectedOption.value = value;
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _submitFormDialog(context);
      final validationMessage = await widget.controller.registerDevice(_selectedOption.value!);
      if (validationMessage['success'] == false) {
        _errorMessage.value = validationMessage['message'];
        _isSubmitting = false;
        GetIt.I<NavigationService>().pop();
        widget.controller.loadingViewState.value = LoadingViewState.loading;
        return;
      } else {
        _isSubmitting = false;
        GetIt.I<NavigationService>().pop();
        widget.controller.loadingViewState.value = LoadingViewState.registerReport;
        return;
      }
    }
    _isSubmitting = false;
  }

  Widget _showMachineTypeDetails() {
    return ValueListenableBuilder(
      valueListenable: _selectedOption,
      builder: (context, machine, child) {
        if (machine == null) {
          return Container();
        }
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 18,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'MÁQUINA SELECIONADA',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  machine.id!,
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'NOME: ',
                      style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      machine.name!.toUpperCase(),
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'ENDEREÇO: ',
                      style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      machine.address!.toUpperCase(),
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'TIPO: ',
                      style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      machine.machineType!.machineType?.toUpperCase() ?? '',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'CATEGORIA DE PRODUTOS: ',
                      style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      machine.machineType!.productClass?.toUpperCase() ?? '',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'SEGMENTO: ',
                      style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      machine.machineType!.machineClass?.toUpperCase() ?? '',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'DESCRIÇÃO: ',
                      style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                    ),
                    Flexible(
                      child: Text(
                        machine.machineType!.describe?.toUpperCase() ?? '',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        softWrap: true,
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'CRIADO EM: ',
                      style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      Utils.utcToLocalTime(machine.machineType?.createdAt! ?? ''),
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Agora vamos associar uma máquina',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.black),
              textAlign: TextAlign.center,
            ),
            Text(
              'Selecione a máquina que será associada à sua Sentinela abaixo',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.black),
              textAlign: TextAlign.center,
            ),
            ValueListenableBuilder(
              // error message text widget
              valueListenable: _errorMessage,
              builder: (context, value, child) {
                return Text(
                  value.toString(),
                  style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                );
              },
            ),
            FutureBuilder(
              key: _futureKey,
              future: widget.controller.getAvailableMachines(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Column(
                    children: [
                      CircularProgressIndicator(color: Colors.tealAccent),
                      SizedBox(height: 10),
                      Text('Buscando máquinas disponíveis', style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.white)),
                    ],
                  );
                } else if (snapshot.data == 'done') {
                  _selectedOption.value = widget.controller.availableMachines.value.machines!.first;
                  return Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        IgnorePointer(
                          ignoring: _isSubmitting,
                          child: DropdownButtonFormField(
                            decoration: InputDecoration(
                              filled: true,
                              //fillColor: Colors.tealAccent,
                              border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)),
                              // prefixIcon: Icon(Icons.key)
                            ),
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.black),
                            //dropdownColor: Colors.tealAccent,
                            borderRadius: BorderRadius.circular(12),
                            icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                            value: _selectedOption.value,
                            items: widget.controller.availableMachines.value.machines!.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(option.name!.toUpperCase(), style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.black)),
                                // alignment: AlignmentDirectional.topStart,
                              );
                            }).toList(),
                            validator: (value) {
                              // if (value == null) {
                              //   _errorMessage.value = 'vazio';
                              //   return;
                              // }
                              return null;
                            },
                            onChanged: (value) {
                              _errorMessage.value = '';
                              _selectedOption.value = value;
                            },
                          ),
                        ),
                        _showMachineTypeDetails(),

                        SizedBox(height: 10),
                        Container(
                          //width: MediaQuery.of(context).size.width * 0.6,
                          width: double.infinity,
                          decoration: BoxDecoration(gradient: Constants.darkGradient, borderRadius: BorderRadius.circular(12)),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 12,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Colors.transparent,
                            ),
                            onPressed: () {
                              _submitForm(_selectedOption.value);
                            },
                            child: Text(
                              'CONFIRMAR',
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          //width: MediaQuery.of(context).size.width * 0.6,
                          width: double.infinity,
                          decoration: BoxDecoration(gradient: Constants.redGradient, borderRadius: BorderRadius.circular(12)),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 12,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Colors.transparent,
                            ),
                            onPressed: () {
                              GetIt.I<NavigationService>().pushReplacement('/loading');
                              //controller.loadingViewState.value = LoadingViewState.getAvailableMachines;
                            },
                            child: Text(
                              'CANCELAR',
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  //! error view - No available machines or conection problems
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: Colors.teal.shade800, borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: Column(
                      children: [
                        Text(
                          snapshot.data!,
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.red.shade300, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                widget.controller.loadingViewState.value = LoadingViewState.getUserSerial;
                              },
                              style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.tealAccent.shade400)),
                              child: Text('Novo Serial', style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.teal.shade900)),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _futureKey = UniqueKey();
                                });
                              },
                              style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.tealAccent.shade400)),
                              child: Text('Buscar Novamente', style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.teal.shade900)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
