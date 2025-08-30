import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lottie/lottie.dart';
import 'package:sentinela_app_pos_simulator/enums/payment_view_stage.dart';
import 'package:sentinela_app_pos_simulator/enums/payment_view_state.dart';
import 'package:sentinela_app_pos_simulator/enums/payment_view_type.dart';
import 'package:sentinela_app_pos_simulator/models/buy_data_model.dart';
import 'package:sentinela_app_pos_simulator/routes/navigation_service.dart';
import 'package:sentinela_app_pos_simulator/services/logger_service.dart';
import 'package:sentinela_app_pos_simulator/src/pagbank.dart';
import 'package:sentinela_app_pos_simulator/src/pages/home/home_controller.dart';
import 'package:sentinela_app_pos_simulator/src/pages/payment/payment_controller.dart';
import 'package:sentinela_app_pos_simulator/src/pages/payment/payment_top_info.dart';
import 'package:sentinela_app_pos_simulator/utils/constants.dart';
import 'package:sentinela_app_pos_simulator/utils/utils.dart';
import 'package:sentinela_app_pos_simulator/widgets/payment_circle_feedback.dart';
import 'package:sentinela_app_pos_simulator/widgets/payment_options.dart';
import 'package:sentinela_app_pos_simulator/widgets/support_info_card.dart';
import 'package:sentinela_app_pos_simulator/widgets/transaction_status_message_display.dart';

class PaymentView extends StatefulWidget {
  const PaymentView({super.key});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  final PaymentViewController paymentController = PaymentViewController();
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = paymentController.initialize();
  }

  @override
  void dispose() {
    paymentController.disposePaymentController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Bloqueia completamente a tentativa de voltar
        debugPrint("Voltar bloqueado. didPop: $didPop, result: $result");
      },
      child: Scaffold(
        body: FutureBuilder(
          future: _initFuture,
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState != ConnectionState.done) {
              return Container(
                decoration: BoxDecoration(gradient: Constants.kbackgroundGradient),
                child: const Center(
                  child: SizedBox(
                    width: 75,
                    height: 75,
                    child: CircularProgressIndicator(color: Colors.white, semanticsLabel: 'Iniciando...', strokeWidth: 8),
                  ),
                ),
              );
            }
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(gradient: Constants.kbackgroundGradient),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ValueListenableBuilder<BuyDataModel>(
                    valueListenable: GetIt.I<HomeController>().buyData,
                    builder: (context, value, child) {
                      return paymentTopInfo(
                        context: context,
                        mediaSize: MediaQuery.of(context),
                        selectedType: value.type,
                        price: Utils.formatBRLMoney(double.parse(value.price)),
                        credits: value.credit.toString(),
                        controller: paymentController,
                      );
                    },
                  ),
                  ValueListenableBuilder(
                    valueListenable: paymentController.paymentViewStage,
                    builder: (context, value, child) {
                      if (value == PaymentViewStage.options) {
                        return paymentOptions(context: context, mediaSize: MediaQuery.of(context), controller: paymentController, gradient: Constants.darkGradient);
                      } else if (value == PaymentViewStage.actions) {
                        return Expanded(child: PaymentActions(controller: paymentController));
                      } else {
                        return Text(' ');
                      }
                    },
                  ),
                  ValueListenableBuilder(
                    valueListenable: paymentController.paymentViewStage,
                    builder: (context, value, child) {
                      if (value == PaymentViewStage.options) {
                        // Back button
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          decoration: BoxDecoration(gradient: Constants.darkGradient, borderRadius: BorderRadius.circular(12)),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 12,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Colors.transparent,
                            ),
                            onPressed: () {
                              GetIt.I<NavigationService>().forceGoHome();
                            },
                            child: Text(
                              'VOLTAR',
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      } else {
                        return SizedBox();
                      }
                    },
                  ),
                  ValueListenableBuilder(
                    valueListenable: paymentController.paymentViewType,
                    builder: (context, value, child) {
                      if (value == PaymentViewTypeEnum.SELECT) {
                        return supportInfoCard(context, paymentController.supportInfo);
                      } else {
                        return SizedBox();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class PaymentActions extends StatelessWidget {
  const PaymentActions({super.key, required this.controller});
  final PaymentViewController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder(
                valueListenable: controller.paymentViewState,
                builder: (context, value, child) {
                  // loading
                  if (value == PaymentViewState.loading) {
                    return PaymentStatusLoading(
                      controller: controller,
                      anim: controller.animationAssetPayment.value,
                      mediaSize: MediaQuery.of(context),
                      repeatAnim: true,
                      sizeAnim: 0.3,
                    );
                  }
                  // waiting card or transaction response
                  else if (value == PaymentViewState.waitingCard) {
                    return Column(
                      children: [
                        PaymentStatusCount(
                          controller: controller,
                          anim: controller.animationAssetPayment.value,
                          count: controller.countSeconds,
                          error: controller.viewStateError.value,
                          mediaSize: MediaQuery.of(context),
                          repeatAnim: true,
                          sizeAnim: 0.3,
                        ),
                      ],
                    );
                  }
                  // waiting password
                  else if (value == PaymentViewState.waitingPassword) {
                    return Column(
                      children: [
                        PaymentStatusLoading(
                          controller: controller,
                          anim: controller.animationAssetPayment.value,
                          mediaSize: MediaQuery.of(context),
                          repeatAnim: true,
                          sizeAnim: 0.3,
                        ),
                      ],
                    );
                  }
                  // waiting remove card
                  else if (value == PaymentViewState.removeCard) {
                    return PaymentStatusLoading(
                      controller: controller,
                      anim: controller.animationAssetPayment.value,
                      mediaSize: MediaQuery.of(context),
                      repeatAnim: true,
                      sizeAnim: 0.3,
                    );
                  }
                  // count card removed
                  else if (value == PaymentViewState.cardRemoved) {
                    return PaymentStatusCount(
                      controller: controller,
                      anim: controller.animationAssetPayment.value,
                      count: controller.countSeconds,
                      mediaSize: MediaQuery.of(context),
                      repeatAnim: true,
                      sizeAnim: 0.3,
                    );
                  }
                  // count pix
                  else if (value == PaymentViewState.pix) {
                    //! make new widget for pix return
                    return PaymentStatusCount(
                      controller: controller,
                      anim: controller.animationAssetPayment.value,
                      count: controller.countSeconds,
                      mediaSize: MediaQuery.of(context),
                      repeatAnim: true,
                      sizeAnim: 0.3,
                    );
                  }
                  // count success
                  else if (value == PaymentViewState.success) {
                    return PaymentStatusCount(
                      controller: controller,
                      anim: controller.animationAssetPayment.value,
                      count: controller.countSeconds,
                      mediaSize: MediaQuery.of(context),
                      repeatAnim: false,
                      sizeAnim: 0.4,
                    );
                  }
                  // inserting credit
                  else if (value == PaymentViewState.insertCredit) {
                    return PaymentStatusCount(
                      controller: controller,
                      anim: controller.animationAssetPayment.value,
                      count: controller.countSeconds,
                      mediaSize: MediaQuery.of(context),
                      repeatAnim: true,
                      sizeAnim: 0.4,
                    );
                  }
                  // inserted credit
                  else if (value == PaymentViewState.creditInserted) {
                    return PaymentStatusCount(
                      controller: controller,
                      anim: controller.animationAssetPayment.value,
                      count: controller.countSeconds,
                      mediaSize: MediaQuery.of(context),
                      repeatAnim: false,
                      sizeAnim: 0.4,
                    );
                  }
                  // on error
                  else if (value == PaymentViewState.error) {
                    return PaymentStatusCount(
                      controller: controller,
                      anim: controller.animationAssetPayment.value,
                      count: controller.countSeconds,
                      //error: controller.viewStateError.value,
                      mediaSize: MediaQuery.of(context),
                      repeatAnim: false,
                      sizeAnim: 0.4,
                    );
                    // on cancel transaction
                  } else if (value == PaymentViewState.abortTransaction) {
                    return PaymentStatusCount(
                      controller: controller,
                      anim: controller.animationAssetPayment.value,
                      count: controller.countSeconds,
                      mediaSize: MediaQuery.of(context),
                      repeatAnim: false,
                      sizeAnim: 0.4,
                    );
                  } else {
                    return SizedBox();
                  }
                },
              ),
              ValueListenableBuilder(
                valueListenable: controller.paymentViewState,
                builder: (context, value, child) {
                  if (value == PaymentViewState.error || value == PaymentViewState.success || value == PaymentViewState.creditInserted) {
                    return Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(gradient: Constants.darkGradient, borderRadius: BorderRadius.circular(12)),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 12,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Colors.transparent,
                            ),
                            onPressed: () {
                              controller.cancelCount = true;
                              controller.backToHome();
                            },
                            child: Text(
                              'FINALIZAR',
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );

                    //* if inserting credit dont show any button
                  } else if (value == PaymentViewState.insertCredit) {
                    return SizedBox();
                  } else {
                    return Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(gradient: Constants.redGradient, borderRadius: BorderRadius.circular(12)),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 12,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Colors.transparent,
                            ),
                            onPressed: () async {
                              controller.abortTransaction();
                            },
                            child: Text(
                              'CANCELAR',
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),

        Expanded(
          flex: 1,
          child: ValueListenableBuilder(
            valueListenable: controller.startSendTEFInterface,
            builder: (context, value, child) {
              if (value) {
                return ValueListenableBuilder(
                  valueListenable: controller.messageInsertCredit,
                  builder: (context, message, child) {
                    return transactionStatusMessageDisplay(context: context, mediaSize: MediaQuery.of(context), message: message.description);
                  },
                );
              } else {
                return ValueListenableBuilder(
                  valueListenable: GetIt.I<PaymentHandlerController>().rawMessagePagbankReturn,
                  builder: (context, message, child) {
                    return transactionStatusMessageDisplay(context: context, mediaSize: MediaQuery.of(context), message: message);
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class PaymentStatusLoading extends StatelessWidget {
  final PaymentViewController controller;
  final String anim;
  final MediaQueryData mediaSize;
  final bool repeatAnim;
  final double sizeAnim;
  const PaymentStatusLoading({super.key, required this.controller, required this.anim, required this.mediaSize, required this.repeatAnim, required this.sizeAnim});

  @override
  Widget build(BuildContext context) {
    controller.cancelCount = true;
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 14),
          width: mediaSize.size.width * 0.5,
          height: mediaSize.size.width * 0.5,
          decoration: Constants.kIconCircleHolder,
          child: Center(
            child: ValueListenableBuilder(
              valueListenable: controller.animationAssetPayment,
              builder: (context, value, child) {
                return Lottie.asset(value, width: mediaSize.size.width * sizeAnim, fit: BoxFit.cover, repeat: repeatAnim);
              },
            ),
          ),
        ),
        LoadingIndicator(),
      ],
    );
  }
}

class PaymentStatusCount extends StatelessWidget {
  final PaymentViewController controller;
  final String anim;
  final int count;
  final MediaQueryData mediaSize;
  final bool repeatAnim;
  final bool error;
  final double sizeAnim;
  const PaymentStatusCount({
    super.key,
    required this.controller,
    required this.anim,
    required this.count,
    this.error = false,
    required this.mediaSize,
    required this.repeatAnim,
    required this.sizeAnim,
  });

  @override
  Widget build(BuildContext context) {
    controller.startCountDownToExecuteFunction(count, () {
      if (error) {
        GetIt.I<LoggerService>().i("Contagem de erro finalizada");
        controller.abortTransaction();
      } else {
        controller.backToHome();
      }
    });

    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 14),
          width: mediaSize.size.width * 0.5,
          height: mediaSize.size.width * 0.5,
          decoration: Constants.kIconCircleHolder,
          child: Center(
            child: ValueListenableBuilder(
              valueListenable: controller.animationAssetPayment,
              builder: (context, value, child) {
                return Lottie.asset(value, width: mediaSize.size.width * sizeAnim, fit: BoxFit.cover, repeat: repeatAnim);
              },
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: controller.circleCount,
          builder: (context, value, child) {
            if (controller.cancelCount == false) {
              return CountDownIndicator(circleCount: controller.circleCount, error: controller.viewStateError.value);
            } else {
              return SizedBox();
            }
          },
        ),
        ValueListenableBuilder(
          valueListenable: controller.countMessage,
          builder: (context, value, child) {
            if (controller.cancelCount == false) {
              return CountLabel(countMessage: controller.countMessage, error: controller.viewStateError.value);
            } else {
              return SizedBox();
            }
          },
        ),
      ],
    );
  }
}
