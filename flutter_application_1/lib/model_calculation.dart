class Instrument {
  final String type; // FUT, CE, PE, EQ
  final String segment; // BCD-FUT, BCD-OPT, etc.
  Instrument({required this.type, required this.segment});
}

class Trade {
  final Instrument instrument;
  final double entryPrice;
  final double exitPrice;
  final int quantity;
  Trade({required this.instrument, required this.entryPrice, required this.exitPrice, required this.quantity});
}
class TradeCalculator {
  static double calculateProfitLoss(Trade trade) {
    // Simplified calculation. Real-world applications may require more detailed calculations.
    switch (trade.instrument.type) {
      case 'FUT': // Futures
      case 'EQ': // Equities
      case 'CE': // Call Options
        return (trade.exitPrice - trade.entryPrice) * trade.quantity;
     
      case 'PE': // Put Options
        // This simplistic model calculates profit/loss for options as the difference in price times quantity.
        // Realistically, options trading calculations would consider strike price, premiums paid/received, etc.
        return (trade.exitPrice - trade.entryPrice) * trade.quantity;
      default:
        return 0.0; // In case of an unknown instrument type
    }
  }
}
