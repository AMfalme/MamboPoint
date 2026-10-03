import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/product.dart';

/// One line of the in-progress sale.
///
/// The unit price is captured when the line is created rather than read back
/// from [Product] later, so editing a product mid-sale cannot silently change
/// what the customer is being charged.
class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get unitPrice => product.sellingPrice;

  double get lineTotal => unitPrice * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);
}

/// The open transaction for the current till session.
///
/// Deliberately UI-only state: it lives in memory, is never written to
/// Firestore, and resets when the app restarts. Checkout — decrementing stock,
/// recording the sale, printing a receipt — belongs to the Sales module and is
/// intentionally not part of this screen.
class CartNotifier extends Notifier<List<CartLine>> {
  @override
  List<CartLine> build() => const <CartLine>[];

  /// Adds one unit of [product], merging into the existing line when the
  /// product is already in the cart. Ignores inactive products so a disabled
  /// item cannot be sold by accident.
  void add(Product product) {
    if (!product.isActive) return;

    final int index = state.indexWhere(
      (CartLine line) => line.product.id == product.id,
    );

    if (index < 0) {
      state = <CartLine>[...state, CartLine(product: product, quantity: 1)];
      return;
    }

    final CartLine line = state[index];
    state = <CartLine>[...state]
      ..[index] = line.copyWith(quantity: line.quantity + 1);
  }

  /// Adds [quantity] units at once, used by the stepper's plus button.
  void addMany(Product product, int quantity) {
    for (int i = 0; i < quantity; i++) {
      add(product);
    }
  }

  /// Removes one unit, dropping the line when it reaches zero.
  void removeOne(String productId) {
    final int index = state.indexWhere(
      (CartLine line) => line.product.id == productId,
    );
    if (index < 0) return;

    final CartLine line = state[index];
    if (line.quantity <= 1) {
      state = <CartLine>[...state]..removeAt(index);
      return;
    }

    state = <CartLine>[...state]
      ..[index] = line.copyWith(quantity: line.quantity - 1);
  }

  /// Sets an absolute quantity. Values below one remove the line, which is what
  /// the stepper's minus button needs at a quantity of one.
  void setQuantity(String productId, int quantity) {
    if (quantity < 1) {
      state = state
          .where((CartLine line) => line.product.id != productId)
          .toList(growable: false);
      return;
    }

    final int index = state.indexWhere(
      (CartLine line) => line.product.id == productId,
    );
    if (index < 0) return;

    state = <CartLine>[...state]
      ..[index] = state[index].copyWith(quantity: quantity);
  }

  void remove(String productId) {
    state = state
        .where((CartLine line) => line.product.id != productId)
        .toList(growable: false);
  }

  void clear() => state = const <CartLine>[];
}

final NotifierProvider<CartNotifier, List<CartLine>> cartProvider =
    NotifierProvider<CartNotifier, List<CartLine>>(CartNotifier.new);

/// Total number of units in the cart — what the badge counts.
final Provider<int> cartCountProvider = Provider<int>((Ref ref) {
  return ref
      .watch(cartProvider)
      .fold<int>(0, (int sum, CartLine line) => sum + line.quantity);
});

/// Number of distinct products in the cart.
final Provider<int> cartLineCountProvider = Provider<int>((Ref ref) {
  return ref.watch(cartProvider).length;
});

/// The amount payable right now.
final Provider<double> cartTotalProvider = Provider<double>((Ref ref) {
  return ref
      .watch(cartProvider)
      .fold<double>(0, (double sum, CartLine line) => sum + line.lineTotal);
});

/// Whether anything has been added. Drives whether the transaction panel is
/// shown at all.
final Provider<bool> cartIsEmptyProvider = Provider<bool>((Ref ref) {
  return ref.watch(cartProvider).isEmpty;
});
