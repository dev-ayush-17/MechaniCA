import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/wallet_api.dart';
import '../domain/wallet_snapshot.dart';

class WalletLedgerState {
  const WalletLedgerState({
    this.balancePaise = 0,
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.status,
  });

  final int balancePaise;
  final List<WalletLedgerItem> items;
  final bool isLoading;
  final String? error;
  final String? status;

  WalletLedgerState copyWith({
    int? balancePaise,
    List<WalletLedgerItem>? items,
    bool? isLoading,
    String? error,
    String? status,
  }) {
    return WalletLedgerState(
      balancePaise: balancePaise ?? this.balancePaise,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      status: status,
    );
  }
}

class WalletLedgerNotifier extends StateNotifier<WalletLedgerState> {
  WalletLedgerNotifier(this._api) : super(const WalletLedgerState(isLoading: true));

  final WalletApi _api;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null, status: null);
    final result = await _api.getWallet();
    result.when(
      onOk: (snap) {
        state = WalletLedgerState(
          balancePaise: snap.balancePaise,
          items: snap.items,
          isLoading: false,
        );
      },
      onErr: (failure) {
        state = WalletLedgerState(isLoading: false, error: failure.message);
      },
    );
  }

  Future<void> addMoney(int amountPaise) async {
    final result = await _api.topup(
      amountPaise: amountPaise,
      idempotencyKey: const Uuid().v4(),
    );
    result.when(
      onOk: (_) {
        state = state.copyWith(status: 'Waiting for confirmation');
      },
      onErr: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }
}
