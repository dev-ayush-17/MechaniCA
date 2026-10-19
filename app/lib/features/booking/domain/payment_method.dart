String paymentMethodCode(String label) {
  return switch (label) {
    'Card' => 'card',
    'Net Banking' => 'netbanking',
    'Wallet' => 'wallet',
    'Cash After Service' => 'cash',
    _ => 'upi',
  };
}
