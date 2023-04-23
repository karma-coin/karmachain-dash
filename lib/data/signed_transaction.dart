import 'package:fixnum/fixnum.dart';
import 'package:karmachain_dash/common_libs.dart';
import 'package:karmachain_dash/services/api/types.pb.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:crypto/crypto.dart';
import 'package:time_ago_provider/time_ago_provider.dart' as time_ago;

/// An extension class over SignedTransaction that supports signing, verification
/// and user read app state
class SignedTransactionWithStatusEx {
  @required
  final SignedTransactionWithStatus txWithStatus;

  /// the transaction's body
  @required
  late final TransactionBody txBody;

  /// the transaction's data. One of the NewUserTransactionV1, PaymentTransactionV1 or UpdateUserTransactionV1
  @required
  late final dynamic txData;

  // Indicate tx is incoming or outgoing or uknown direction in current context
  @required
  late bool? incoming;

  // true if user has opened the tx details in the app
  final ValueNotifier<bool> openned = ValueNotifier<bool>(false);

  SignedTransactionWithStatusEx(this.txWithStatus, bool? isIncoming) {
    incoming = isIncoming;
    txBody =
        TransactionBody.fromBuffer(txWithStatus.transaction.transactionBody);

    switch (txBody.transactionData.transactionType) {
      case TransactionType.TRANSACTION_TYPE_NEW_USER_V1:
        txData = NewUserTransactionV1.fromBuffer(
            txBody.transactionData.transactionData);
        break;
      case TransactionType.TRANSACTION_TYPE_PAYMENT_V1:
        txData = PaymentTransactionV1.fromBuffer(
            txBody.transactionData.transactionData);
        break;
      case TransactionType.TRANSACTION_TYPE_UPDATE_USER_V1:
        txData = UpdateUserTransactionV1.fromBuffer(
            txBody.transactionData.transactionData);
        break;
      default:
        throw Exception('Unknown transaction type');
    }
  }

  TransactionType get txType => txBody.transactionData.transactionType;

  TransactionStatus get status => txWithStatus.status;

  PaymentTransactionV1? getPaymentData() {
    if (txData is PaymentTransactionV1) {
      return txData as PaymentTransactionV1;
    } else {
      return null;
    }
  }

  String getStatusDisplayString() {
    switch (status) {
      case TransactionStatus.TRANSACTION_STATUS_SUBMITTED:
        return 'PENDING';
      case TransactionStatus.TRANSACTION_STATUS_ON_CHAIN:
        return 'CONFIRMED';
      case TransactionStatus.TRANSACTION_STATUS_REJECTED:
        return 'FAILED';
      default:
        return 'UNKNOWN';
    }
  }

  Color getStatusDisplayColor() {
    switch (status) {
      case TransactionStatus.TRANSACTION_STATUS_SUBMITTED:
        return CupertinoColors.systemOrange;
      case TransactionStatus.TRANSACTION_STATUS_ON_CHAIN:
        return CupertinoColors.activeGreen;
      case TransactionStatus.TRANSACTION_STATUS_REJECTED:
        return CupertinoColors.destructiveRed;
      default:
        return CupertinoColors.systemOrange;
    }
  }

  Int64 getTimeStamp() {
    return txBody.timestamp;
  }

  /// Sign the transaction using the provided private key and
  /// set the tx signature to the result
  void sign(ed.PrivateKey privateKey,
      {keyScheme = KeyScheme.KEY_SCHEME_ED25519}) {
    Uint8List signature = ed.sign(privateKey,
        Uint8List.fromList(txWithStatus.transaction.transactionBody));
    txWithStatus.transaction.signature =
        Signature(scheme: keyScheme, signature: signature.toList());
  }

  /// Verify the transaction using its signature
  bool verify(ed.PublicKey publicKey,
      {keyScheme = KeyScheme.KEY_SCHEME_ED25519}) {
    if (keyScheme != KeyScheme.KEY_SCHEME_ED25519) {
      debugPrint('Only ed scheme is currently supported');
      return false;
    }

    return ed.verify(
        publicKey,
        Uint8List.fromList(txWithStatus.transaction.transactionBody),
        Uint8List.fromList(txWithStatus.transaction.signature.signature));
  }

  /// Create a new SignedTransactionWithStatus from json representation
  static SignedTransactionWithStatusEx fromJson(Map<String, dynamic> value) {
    String txData = value['txWithStatus'];
    SignedTransactionWithStatus tx =
        SignedTransactionWithStatus.fromJson(txData);

    SignedTransactionWithStatusEx txWithStatus = SignedTransactionWithStatusEx(
        tx, value['incoming'] == 'true' || value['incoming'] == true);
    txWithStatus.openned.value = value['openned'];
    return txWithStatus;
  }

  // Returns a json representation of the tx
  Map<String, dynamic> toJson() {
    return {
      'txWithStatus': txWithStatus.writeToJson(),
      'openned': openned.value,
      'incoming': incoming
    };
  }

  /// Returns the from user which with accountId identical to signer account id
  User? getFromUser() {
    if (txWithStatus.hasFrom()) {
      return txWithStatus.from;
    } else {
      return null;
    }
  }

  List<int> getFromUserAccountId() {
    return txWithStatus.transaction.signer.data;
  }

  String getTimesAgo() {
    return time_ago
        .format(DateTime.fromMillisecondsSinceEpoch(txBody.timestamp.toInt()));
  }

  Int64 getNonce() {
    return txBody.nonce;
  }

  /// Returns to user if the transaction is an on-chain payment transaction
  User? getToUser() {
    if (txWithStatus.hasTo()) {
      return txWithStatus.to;
    } else {
      return null;
    }
  }

  /// Returns the canonical tx hash - used for indexing
  List<int> getHash() {
    // we downgraded to sha256 as blake dart libs such as r_crypto are native only
    return sha256.convert(txWithStatus.transaction.transactionBody).bytes;
  }

  String getTransactionTypeDisplayName() {
    switch (txType) {
      case TransactionType.TRANSACTION_TYPE_NEW_USER_V1:
        return 'Signup transaction';
      case TransactionType.TRANSACTION_TYPE_PAYMENT_V1:
        {
          PaymentTransactionV1 payment = txData as PaymentTransactionV1;
          if (payment.charTraitId != 0) {
            return 'Appreciation';
          } else {
            return 'Payment';
          }
        }
      case TransactionType.TRANSACTION_TYPE_UPDATE_USER_V1:
        return '👩‍💻 Account update transaction';
      default:
        return '⚠️ Unrecognized transaction type';
    }
  }

  String getTransactionTypeDisplayNameWithDirection(bool incoming) {
    String name = getTransactionTypeDisplayName();
    if (incoming) {
      name += ' (receieved)';
    } else {
      name += ' (sent)';
    }
    return name;
  }
}
