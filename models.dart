class Product {
  final String id, emoji, name, weight;
  final int price, mrp;
  const Product(this.id, this.emoji, this.name, this.weight, this.price, this.mrp);
  int get off => ((mrp - price) / mrp * 100).round();
}

class Shop {
  final String id, emoji, name, eta;
  final double rating, km;
  const Shop(this.id, this.emoji, this.name, this.rating, this.eta, this.km);
}

// Sample catalogue. Later: replace with Firestore `products` / `shops` streams.
const kCats = [
  ['🛒', 'Groceries'],
  ['🥬', 'Fresh Vegetables'],
  ['💊', 'Medicines'],
  ['🍬', 'Sweets & Snacks'],
  ['🏪', 'General Store'],
];

const kShops = [
  Shop('s1', '🏪', 'Maa Durga Kirana Store', 4.6, '30–40 mins', 1.2),
  Shop('s2', '🛒', 'Shree Ram General Store', 4.4, '35–45 mins', 1.8),
  Shop('s3', '🍬', 'Murarai Sweets & Snacks', 4.8, '25–35 mins', 2.4),
  Shop('s4', '💊', 'Jan Seva Medical', 4.5, '30–40 mins', 1.5),
];

const kProducts = [
  Product('p1', '🍚', 'Basmati Rice', '1 kg', 78, 90),
  Product('p2', '🧅', 'Fresh Onion', '1 kg', 32, 40),
  Product('p3', '🥛', 'Toned Milk', '500 ml', 28, 30),
  Product('p4', '🍅', 'Tomato', '500 g', 22, 28),
  Product('p5', '🛢️', 'Mustard Oil', '1 L', 155, 175),
  Product('p6', '🍬', 'Rasgulla Tin', '500 g', 120, 140),
  Product('p7', '💊', 'Paracetamol Strip', '10 tabs', 18, 20),
  Product('p8', '🧼', 'Bath Soap', '100 g', 36, 42),
];
