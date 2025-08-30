import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lottie/lottie.dart';
import 'package:sentinela_app_pos_simulator/enums/payment_view_type.dart';
import 'package:sentinela_app_pos_simulator/routes/navigation_service.dart';
import 'package:sentinela_app_pos_simulator/services/logger_service.dart';
import 'package:sentinela_app_pos_simulator/src/pages/home/home_controller.dart';
import 'package:sentinela_app_pos_simulator/utils/constants.dart';
import 'package:sentinela_app_pos_simulator/utils/logger_util.dart';
import 'package:sentinela_app_pos_simulator/widgets/app_info_card.dart';
import 'package:sentinela_app_pos_simulator/widgets/select_value_button.dart';
import 'package:sentinela_app_pos_simulator/widgets/support_info_card.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late HomeController homeController;
  late final Future<bool> _initFuture;
  // get arguments from the previous page

  @override
  void initState() {
    super.initState();
    homeController = GetIt.I<HomeController>();
    _initFuture = homeController.initializeHomeData();
  }

  @override
  void dispose() {
    homeController.disposeHomeController();
    super.dispose();
    GetIt.I<LoggerService>().w("Home disposed");
  }

  @override
  Widget build(BuildContext context) {
    logger.w("HomeView build called");
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Bloqueia completamente a tentativa de voltar
        debugPrint("Voltar bloqueado. didPop: $didPop, result: $result");
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: Constants.kbackgroundGradient),
          child: FutureBuilder(
            future: _initFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // * populando configurações iniciais
                    Center(
                      child: AutoSizeText(
                        'Iniciando valores',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 8.0, color: Colors.black.withAlpha(100), offset: Offset(2, 2))],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        minFontSize: 16,
                        maxFontSize: 21,
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(width: 75, height: 75, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 8)),
                  ],
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Ocorreu um erro.', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white)),
                );
              }
              return ValueListenableBuilder(
                valueListenable: homeController.isBlocked,
                builder: (context, value, child) {
                  if (value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          SizedBox(child: Lottie.asset('assets/lottie/sentinela-spolus.json', width: 200, height: 200, reverse: true, repeat: true)),
                          Text(
                            'A Sentinela está inoperante.',
                            style: TextStyle(color: Colors.yellow[700], fontSize: 26, fontWeight: FontWeight.w900),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Por favor, entre em contato com o suporte.',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(gradient: Constants.kbackgroundGradient),
                    child: ValueListenableBuilder(
                      valueListenable: homeController.hasInternetConnection,
                      builder: (context, hasInternet, child) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // * Exibe informações do app
                            appInfoCard(context, homeController.sentinelaSpolusAppInfos, homeController.sentinelaGlobalStatusColor),
                            if (!hasInternet)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: AutoSizeText(
                                  'Sem conexão com a internet.\nPor favor, aguarde, ou entre em contato com o suporte.',
                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    color: Colors.yellowAccent,
                                    fontWeight: FontWeight.w900,
                                    shadows: [Shadow(blurRadius: 4.0, color: Colors.black.withAlpha(100), offset: Offset(0.5, 0.5))],
                                  ),
                                  minFontSize: 21,
                                  maxFontSize: 26,
                                  textAlign: TextAlign.center,
                                  maxLines: 4,
                                  softWrap: true,
                                ),
                              ),
                            if (hasInternet)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Column(
                                  children: [
                                    ValueListenableBuilder(
                                      valueListenable: homeController.homePaymentTypesEnabledTitle,
                                      builder: (context, value, child) {
                                        return AutoSizeText(
                                          value,
                                          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                            color: Color(0xFF213A58),
                                            fontWeight: FontWeight.bold,
                                            shadows: [Shadow(blurRadius: 4.0, color: Colors.black.withAlpha(100), offset: Offset(0.5, 0.5))],
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          minFontSize: 16,
                                          maxFontSize: 24,
                                        );
                                      },
                                    ),
                                    SizedBox(height: 6),
                                    AutoSizeText(
                                      'Selecione uma das opções abaixo,\nem seguida escolha a forma de pagamento.',
                                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                        height: 1,
                                        shadows: [Shadow(blurRadius: 4.0, color: Colors.black.withAlpha(100), offset: Offset(0.5, 0.5))],
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 4,
                                      softWrap: true,
                                    ),
                                  ],
                                ),
                              ),

                            // * Caso esteja habilitado o pagamento por TEF, exibe as opções de pagamento.
                            if (hasInternet)
                              if (homeController.defaultInicializationSettings.defaultStateTef == true)
                                ValueListenableBuilder(
                                  valueListenable: homeController.machineIsTurnnedOn,
                                  builder: (context, value, child) {
                                    if (!value) {
                                      return Expanded(
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(child: Lottie.asset('assets/lottie/sentinela-spolus.json', width: 200, height: 200, reverse: true, repeat: true)),
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: RichText(
                                                  text: TextSpan(
                                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w900,
                                                      shadows: [Shadow(blurRadius: 4.0, color: Colors.black.withAlpha(100), offset: Offset(0.5, 0.5))],
                                                      //fontSize: 21,
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                        text: 'Máquina desligada.\n',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.w900,
                                                          fontSize: 31,
                                                          shadows: [Shadow(blurRadius: 8.0, color: Colors.black.withAlpha(100), offset: Offset(2, 2))],
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: 'Por favor, volte mais tarde.\n',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.w900,
                                                          fontSize: 18,
                                                          shadows: [Shadow(blurRadius: 8.0, color: Colors.black.withAlpha(100), offset: Offset(2, 2))],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 4,
                                                  softWrap: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    } else {
                                      return Expanded(
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            return SingleChildScrollView(
                                              physics: const BouncingScrollPhysics(),
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                                child: IntrinsicHeight(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: homeController.priceOptionsList.priceOpts!
                                                        .map(
                                                          (item) => Padding(
                                                            padding: const EdgeInsets.only(bottom: 12.0),
                                                            child: selectButtonValueToPay(
                                                              context: context,
                                                              mediaSize: MediaQuery.of(context),
                                                              price: item.price!,
                                                              credits: item.credits!,
                                                              onPressed: () {
                                                                homeController.buyData.value = homeController.buyData.value.copyWith(
                                                                  price: item.price,
                                                                  credit: item.credits,
                                                                  type: PaymentViewTypeEnum.SELECT,
                                                                );
                                                                GetIt.I<LoggerService>().w("VENDA SELECIONADA: ${homeController.buyData.value.toJson()}");
                                                                GetIt.I<NavigationService>().pushTo('/payment');
                                                              },
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }
                                  },
                                ),
                            // * Caso não esteja habilitado o pagamento por TEF, exibe as opções de pagamento.
                            if (homeController.defaultInicializationSettings.defaultStateTef == false)
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'No momento, não há opções de pagamento via cartão disponíveis.',
                                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          shadows: [Shadow(blurRadius: 4.0, color: Colors.black.withAlpha(100), offset: Offset(0.5, 0.5))],
                                          fontSize: 21,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 4,
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            supportInfoCard(context, homeController.supportInfo),
                          ],
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
