# 🎭 Simulador de Pagamento POS

Este documento descreve as modificações realizadas para transformar a aplicação em um simulador, removendo a dependência real da biblioteca `pagseguro_smart_flutter` e implementando um sistema de simulação de pagamentos.

## 📝 Modificações Realizadas

### 1. Criação do Simulador de Pagamento

-   **Arquivo**: `lib/src/simulator/payment_simulator.dart`
-   **Descrição**: Simulador completo que substitui a funcionalidade da biblioteca PagSeguro
-   **Funcionalidades**:
    -   Simulação de ativação de pinpad
    -   Simulação de pagamentos (Crédito, Débito, PIX)
    -   Simulação de cancelamento de transações
    -   Simulação de reinicialização do dispositivo
    -   Geração de dados mock para transações

### 2. Remoção da Dependência Real

-   **Arquivo**: `pubspec.yaml`
-   **Modificação**: Removida a dependência `pagseguro_smart_flutter`
-   **Impacto**: A aplicação não depende mais da biblioteca real do PagSeguro

### 3. Atualização dos Controllers

-   **Arquivos modificados**:
    -   `lib/src/pagbank.dart`
    -   `lib/src/pages/payment/payment_controller.dart`
    -   `lib/src/pages/home/home_controller.dart`
-   **Modificações**: Todas as chamadas para `PagseguroSmart.instance()` foram substituídas por `PaymentSimulator.instance()`

## 🎮 Como Funciona o Simulador

### Comportamento de Simulação

-   **Taxa de Sucesso**: 90% dos pagamentos são aprovados
-   **Valores de Teste**: Valores específicos (R$ 0,01, R$ 6,66, R$ 9,99) sempre resultam em falha
-   **Tempos Realistas**: O simulador respeita delays similares ao mundo real

### Fluxo de Pagamento Simulado

1. **Ativação**: Simula a ativação do pinpad com código
2. **Aguardando Cartão**: Exibe mensagem "APROXIME, INSIRA OU PASSE O CARTAO"
3. **Processamento**: Simula processamento da transação
4. **Autorização**: Simula autorização da transação
5. **Remoção do Cartão**: Para crédito/débito, simula remoção do cartão
6. **Finalização**: Gera dados mock da transação

### Dados Gerados pelo Simulador

-   Código de transação único
-   ID de transação
-   Bandeira do cartão (Visa, Mastercard, Elo, Amex)
-   Máscara do cartão
-   Código de autorização
-   Comprovante de pagamento

## 🔧 Configuração de Teste

### Valores Especiais para Teste

```dart
// Valores que sempre falham (para teste)
R$ 0,01 -> Sempre falha
R$ 6,66 -> Sempre falha
R$ 9,99 -> Sempre falha

// Outros valores
90% de chance de sucesso
```

### Tipos de Erro Simulados

-   "CARTÃO NEGADO"
-   "SALDO INSUFICIENTE"
-   "CARTÃO BLOQUEADO"
-   "ERRO DE COMUNICAÇÃO"

## 🎯 Vantagens do Simulador

1. **Desenvolvimento Independente**: Não precisa de hardware ou credenciais reais
2. **Testes Reproduzíveis**: Comportamento consistente para testes automatizados
3. **Cenários Controlados**: Pode simular diferentes cenários de sucesso e falha
4. **Desenvolvimento Offline**: Funciona sem conexão com serviços externos
5. **Debugging Facilitado**: Logs detalhados de cada etapa da simulação

## 🔍 Logs do Simulador

O simulador produz logs detalhados identificados pelo emoji 🎭:

-   `🎭 PaymentSimulator inicializado`
-   `🎭 Simulando ativação do pinpad com código: XXXXX`
-   `🎭 Simulando pagamento [TIPO] de R$ X.XX`
-   `🎭 Simulando cancelamento de transação`

## ⚠️ Importante

Este simulador é destinado apenas para **desenvolvimento e testes**. Para uso em produção, a dependência real do `pagseguro_smart_flutter` deve ser restaurada e configurada adequadamente.

## 🔄 Restaurando a Funcionalidade Real

Para voltar a usar a biblioteca real:

1. Adicione a dependência no `pubspec.yaml`
2. Substitua `PaymentSimulator.instance()` por `PagseguroSmart.instance()`
3. Restaure os imports corretos
4. Configure as credenciais reais do PagSeguro

---

**Desenvolvido para facilitar o desenvolvimento e testes da aplicação Sentinela POS Simulator** 🚀
