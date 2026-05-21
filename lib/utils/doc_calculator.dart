class DocCalculator {
  // Menghitung hari budidaya (Days Of Culture) dari tanggal stocking
  static int calculateDoc(DateTime stockingDate) {
    final difference = DateTime.now().difference(stockingDate).inDays;
    return difference >= 0 ? difference : 0;
  }
}
