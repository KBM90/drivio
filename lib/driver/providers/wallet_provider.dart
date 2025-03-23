import 'package:flutter/material.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  Wallet? _wallet;

  Wallet? get wallet => _wallet;

  Future<void> fetchWallet() async {
    _wallet = await WalletService().getWallet();
    notifyListeners();
  }
}
