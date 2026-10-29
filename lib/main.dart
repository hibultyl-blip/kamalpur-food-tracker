import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const navy = Color(0xFF1B3F6B);
const orange = Color(0xFFC2571A);
const teal = Color(0xFF1F7F7B);
const bgGrey = Color(0xFFF4F7FA);
const inkGrey = Color(0xFF4A5B70);
const developerLine = 'Developed by Sandipan foody';
const deliveryFee = 25;

// ---------------------------------------------------------------- models

class MenuItem {
  String name;
  String desc;
  int price;
  String category;
  String? photoPath;
  bool available;
  MenuItem({
    required this.name,
    this.desc = '',
    required this.price,
    this.category = '',
    this.photoPath,
    this.available = true,
  });
}

class Restaurant {
  final String name;
  final String cuisine;
  final String eta;
  final double rating;
  final String offer;
  final Color tint;
  String? photoPath;
  final List<MenuItem> items;
  Restaurant({
    required this.name,
    required this.cuisine,
    this.eta = '30-40 min',
    this.rating = 4.2,
    this.offer = '',
    this.tint = const Color(0xFF8A5A2B),
    this.photoPath,
    required this.items,
  });
}

class OrderLine {
  final MenuItem item;
  final int qty;
  OrderLine(this.item, this.qty);
}

class Order {
  final int id;
  final Restaurant restaurant;
  final List<OrderLine> lines;
  final int total;
  final String payment;
  final String address;
  int stage = 0; // 0 placed, 1 preparing, 2 on the way, 3 delivered
  bool rejected = false;
  bool autoAdvance;
  Order({
    required this.id,
    required this.restaurant,
    required this.lines,
    required this.total,
    required this.payment,
    required this.address,
    required this.autoAdvance,
  });
}

// ---------------------------------------------------------------- state

class AppState extends ChangeNotifier {
  final List<Restaurant> restaurants = [
    Restaurant(
      name: 'Restaurant One',
      cuisine: 'North Indian, Chinese',
      eta: '30-40 min',
      rating: 4.3,
      offer: '20% off',
      tint: const Color(0xFF8A5A2B),
      items: [
        MenuItem(name: 'Chicken Biryani', desc: 'Served with raita', price: 180, category: 'Biryani'),
        MenuItem(name: 'Veg Fried Rice', desc: 'With gravy', price: 120, category: 'Chinese'),
        MenuItem(name: 'Chilli Chicken', desc: 'Dry, spicy', price: 160, category: 'Chinese'),
      ],
    ),
    Restaurant(
      name: 'Restaurant Two',
      cuisine: 'Biryani, Rolls',
      eta: '25-35 min',
      rating: 4.1,
      offer: 'Free delivery',
      tint: const Color(0xFF5E7B4B),
      items: [
        MenuItem(name: 'Mutton Biryani', desc: 'Half plate', price: 220, category: 'Biryani'),
        MenuItem(name: 'Egg Roll', desc: 'Double egg', price: 60, category: 'Snacks'),
        MenuItem(name: 'Gulab Jamun', desc: '2 pieces', price: 40, category: 'Sweets'),
      ],
    ),
  ];

  Restaurant? myRestaurant;
  final Map<MenuItem, int> cart = {};
  Restaurant? cartRestaurant;
  final List<Order> orders = [];
  int _nextId = 1;
  Timer? _timer;

  AppState() {
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _tick());
  }

  void _tick() {
    var changed = false;
    for (final o in orders) {
      if (!o.rejected && o.autoAdvance && o.stage < 3) {
        o.stage++;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  int get cartCount => cart.values.fold(0, (a, b) => a + b);
  int get cartSubtotal => cart.entries.fold(0, (a, e) => a + e.key.price * e.value);

  void addToCart(Restaurant r, MenuItem item) {
    if (cartRestaurant != r) {
      cart.clear();
      cartRestaurant = r;
    }
    cart[item] = (cart[item] ?? 0) + 1;
    notifyListeners();
  }

  void removeFromCart(MenuItem item) {
    final q = cart[item] ?? 0;
    if (q <= 1) {
      cart.remove(item);
    } else {
      cart[item] = q - 1;
    }
    if (cart.isEmpty) cartRestaurant = null;
    notifyListeners();
  }

  Order placeOrder(String payment, String address) {
    final r = cartRestaurant!;
    final lines = cart.entries.map((e) => OrderLine(e.key, e.value)).toList();
    final order = Order(
      id: _nextId++,
      restaurant: r,
      lines: lines,
      total: cartSubtotal + deliveryFee,
      payment: payment,
      address: address,
      autoAdvance: r != myRestaurant,
    );
    orders.insert(0, order);
    cart.clear();
    cartRestaurant = null;
    notifyListeners();
    return order;
  }

  void registerRestaurant(String name, String cuisine, String? photo) {
    final r = Restaurant(
      name: name,
      cuisine: cuisine.isEmpty ? 'Restaurant' : cuisine,
      photoPath: photo,
      items: [],
    );
    restaurants.add(r);
    myRestaurant = r;
    notifyListeners();
  }

  void addMenuItem(MenuItem item) {
    myRestaurant?.items.add(item);
    notifyListeners();
  }

  void removeMenuItem(MenuItem item) {
    myRestaurant?.items.remove(item);
    notifyListeners();
  }

  void toggleAvailable(MenuItem item) {
    item.available = !item.available;
    notifyListeners();
  }

  void acceptOrder(Order o) {
    o.autoAdvance = true;
    o.stage = 1;
    notifyListeners();
  }

  void rejectOrder(Order o) {
    o.rejected = true;
    notifyListeners();
  }
}

final appState = AppState();

// ---------------------------------------------------------------- app

void main() {
  runApp(const KamalpurApp());
}

class KamalpurApp extends StatelessWidget {
  const KamalpurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kamalpur Food Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy),
        scaffoldBackgroundColor: bgGrey,
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFFBEBDD),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ---------------------------------------------------------------- shared widgets

class FoodPhoto extends StatelessWidget {
  final String? path;
  final double size;
  final Color color;
  const FoodPhoto({
    super.key,
    this.path,
    required this.size,
    this.color = const Color(0xFFB8742F),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: path != null
            ? Image.file(File(path!), fit: BoxFit.cover)
            : Container(
                color: color,
                child: Icon(Icons.ramen_dining, color: Colors.white, size: size * 0.45),
              ),
      ),
    );
  }
}

class DeveloperFooter extends StatelessWidget {
  const DeveloperFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(developerLine, style: TextStyle(color: inkGrey, fontSize: 13)),
      ),
    );
  }
}

class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const BigButton({super.key, required this.label, required this.onTap, this.color = orange});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

InputDecoration fieldStyle(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFC5D1DE)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFC5D1DE)),
    ),
  );
}

// ---------------------------------------------------------------- splash

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/icon.png', width: 240, height: 240),
                    const SizedBox(height: 20),
                    const Text(
                      'Kamalpur Food Tracker',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: navy),
                    ),
                    const SizedBox(height: 6),
                    const Text('Fast. Fresh. Reliable.', style: TextStyle(color: inkGrey, fontSize: 16)),
                  ],
                ),
              ),
            ),
            const CircularProgressIndicator(color: orange),
            const SizedBox(height: 12),
            const Text('Loading...', style: TextStyle(color: inkGrey)),
            const SizedBox(height: 16),
            const Text(developerLine, style: TextStyle(color: inkGrey, fontSize: 13)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- shell

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [HomeTab(), OrdersTab(), SupportTab(), ProfileTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.headset_mic_outlined), selectedIcon: Icon(Icons.headset_mic), label: 'Support'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- home

const categories = ['All', 'Biryani', 'Chinese', 'Snacks', 'Sweets'];

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String query = '';
  String category = 'All';

  bool matches(Restaurant r) {
    final q = query.trim().toLowerCase();
    final textOk = q.isEmpty ||
        r.name.toLowerCase().contains(q) ||
        r.cuisine.toLowerCase().contains(q) ||
        r.items.any((i) => i.name.toLowerCase().contains(q));
    final catOk = category == 'All' ||
        r.cuisine.toLowerCase().contains(category.toLowerCase()) ||
        r.items.any((i) => i.category.toLowerCase() == category.toLowerCase());
    return textOk && catOk;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final list = appState.restaurants.where(matches).toList();
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                color: navy,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Deliver to', style: TextStyle(color: Color(0xFFD6E2F0), fontSize: 13)),
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white, size: 20),
                        SizedBox(width: 4),
                        Text('Kamalpur, Tripura',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      onChanged: (v) => setState(() => query = v),
                      decoration: fieldStyle('Search restaurants or dishes').copyWith(
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today's offer", style: TextStyle(color: Colors.white, fontSize: 12)),
                          Text('Free delivery',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                          Text('on your first order', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.delivery_dining, color: Colors.white, size: 56),
                  ],
                ),
              ),
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  children: [
                    for (final c in categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: category == c,
                          selectedColor: orange,
                          labelStyle: TextStyle(
                            color: category == c ? Colors.white : navy,
                            fontWeight: FontWeight.w700,
                          ),
                          showCheckmark: false,
                          onSelected: (_) => setState(() => category = c),
                        ),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text('Restaurants near you', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No restaurants found.', style: TextStyle(color: inkGrey))),
                ),
              for (final r in list) RestaurantCard(restaurant: r),
              const DeveloperFooter(),
            ],
          ),
        );
      },
    );
  }
}

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const RestaurantCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MenuScreen(restaurant: r)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    r.photoPath != null
                        ? Image.file(File(r.photoPath!), fit: BoxFit.cover)
                        : Container(
                            color: r.tint,
                            child: const Icon(Icons.restaurant, color: Colors.white, size: 44),
                          ),
                    if (r.offer.isNotEmpty)
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: Text(r.offer, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(r.cuisine, style: const TextStyle(color: inkGrey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: teal, borderRadius: BorderRadius.circular(6)),
                          child: Text('${r.rating} ★',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 4),
                        Text(r.eta, style: const TextStyle(color: inkGrey, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- menu

class MenuScreen extends StatelessWidget {
  final Restaurant restaurant;
  const MenuScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final r = restaurant;
        final showBar = appState.cartCount > 0 && appState.cartRestaurant == r;
        return Scaffold(
          appBar: AppBar(title: Text(r.name)),
          body: ListView(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${r.cuisine}  ·  ${r.eta}', style: const TextStyle(color: inkGrey)),
                    const SizedBox(height: 8),
                    const Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text('COD available'), backgroundColor: Color(0xFFE3F1F0)),
                        Chip(label: Text('Online payment'), backgroundColor: Color(0xFFE3F1F0)),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              if (r.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('This restaurant has not added dishes yet.', style: TextStyle(color: inkGrey))),
                ),
              for (final item in r.items) MenuRow(restaurant: r, item: item),
              const DeveloperFooter(),
            ],
          ),
          bottomNavigationBar: showBar
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SizedBox(
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: navy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${appState.cartCount} items · Rs. ${appState.cartSubtotal}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            const Text('View cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class MenuRow extends StatelessWidget {
  final Restaurant restaurant;
  final MenuItem item;
  const MenuRow({super.key, required this.restaurant, required this.item});

  @override
  Widget build(BuildContext context) {
    final qty = appState.cart[item] ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          FoodPhoto(path: item.photoPath, size: 84),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                if (item.desc.isNotEmpty) Text(item.desc, style: const TextStyle(color: inkGrey, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Rs. ${item.price}',
                    style: const TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          if (!item.available)
            const Text('Sold out', style: TextStyle(color: inkGrey, fontWeight: FontWeight.w700))
          else if (qty == 0)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: orange,
                minimumSize: const Size(76, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => appState.addToCart(restaurant, item),
              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          else
            Container(
              decoration: BoxDecoration(color: const Color(0xFFFBEBDD), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => appState.removeFromCart(item),
                    icon: const Icon(Icons.remove, color: orange),
                  ),
                  Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  IconButton(
                    onPressed: () => appState.addToCart(restaurant, item),
                    icon: const Icon(Icons.add, color: orange),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- cart

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final address = TextEditingController(text: 'House no., street, Kamalpur, Tripura');
  String payment = 'Cash on delivery';

  @override
  void dispose() {
    address.dispose();
    super.dispose();
  }

  Future<void> place() async {
    if (address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your delivery address')));
      return;
    }
    if (payment == 'Online payment') {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Online payment'),
          content: const Text(
              'Online payment will be connected with Razorpay after your business account is ready. For now this order is saved as a demo online payment.'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Continue'))],
        ),
      );
      if (!mounted) return;
    }
    final order = appState.placeOrder(payment, address.text.trim());
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => TrackingScreen(order: order)),
      (route) => route.isFirst,
    );
  }

  Widget payTile(String label, String sub) {
    final selected = payment == label;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? orange : Colors.white, width: 2),
      ),
      child: ListTile(
        onTap: () => setState(() => payment = label),
        leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: selected ? orange : inkGrey),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(sub),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final r = appState.cartRestaurant;
        if (r == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Your cart')),
            body: const Center(child: Text('Your cart is empty.')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Your cart')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: const TextStyle(color: inkGrey, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    for (final e in appState.cart.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${e.key.name} x ${e.value}')),
                            Text('Rs. ${e.key.price * e.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery fee', style: TextStyle(color: inkGrey)),
                        Text('Rs. $deliveryFee'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        Text('Rs. ${appState.cartSubtotal + deliveryFee}',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Delivery address', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(controller: address, decoration: fieldStyle('House no., street, Kamalpur')),
              const SizedBox(height: 16),
              const Text('Payment method', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              payTile('Cash on delivery', 'Pay the rider when food arrives'),
              payTile('Online payment', 'UPI, cards, net banking'),
              const SizedBox(height: 8),
              BigButton(label: 'Place order', onTap: place),
              const DeveloperFooter(),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- tracking

const stageNames = ['Order placed', 'Preparing your food', 'On the way', 'Delivered'];
const stageProgress = [0.0, 0.25, 0.65, 1.0];

class TrackingScreen extends StatelessWidget {
  final Order order;
  const TrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final waiting = !order.autoAdvance && !order.rejected;
        final title = order.rejected
            ? 'Order rejected'
            : waiting
                ? 'Waiting for the restaurant'
                : stageNames[order.stage];
        return Scaffold(
          appBar: AppBar(title: Text('Order #${order.id}')),
          body: Column(
            children: [
              SizedBox(
                height: 280,
                width: double.infinity,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: stageProgress[order.stage]),
                  duration: const Duration(seconds: 2),
                  builder: (context, t, _) => CustomPaint(painter: MapPainter(t)),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    children: [
                      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('Order from ${order.restaurant.name}', style: const TextStyle(color: inkGrey)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          for (var i = 0; i < 4; i++)
                            Expanded(
                              child: Container(
                                height: 6,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: (i <= order.stage && !waiting && !order.rejected)
                                      ? teal
                                      : const Color(0xFFDDE5EE),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            const CircleAvatar(backgroundColor: Color(0xFFC9D6E4), child: Text('R')),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Delivery partner', style: TextStyle(fontWeight: FontWeight.w800)),
                                  Text('${order.payment}: Rs. ${order.total}',
                                      style: const TextStyle(color: inkGrey, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 50),
                                side: const BorderSide(color: navy, width: 1.5),
                                foregroundColor: navy,
                              ),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ChatScreen()),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Chat support'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 50),
                                backgroundColor: navy,
                              ),
                              onPressed: () => showCareDialog(context),
                              icon: const Icon(Icons.headset_mic),
                              label: const Text('Customer care'),
                            ),
                          ),
                        ],
                      ),
                      const DeveloperFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MapPainter extends CustomPainter {
  final double t;
  MapPainter(this.t);

  static const pts = [Offset(0.18, 0.82), Offset(0.18, 0.5), Offset(0.72, 0.5), Offset(0.72, 0.18)];

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFDCE8E6));
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    for (final y in [0.2, 0.5, 0.82]) {
      canvas.drawLine(Offset(0, s.height * y), Offset(s.width, s.height * y), road);
    }
    for (final x in [0.18, 0.45, 0.72]) {
      canvas.drawLine(Offset(s.width * x, 0), Offset(s.width * x, s.height), road);
    }
    final points = pts.map((f) => Offset(f.dx * s.width, f.dy * s.height)).toList();
    final route = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      route.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      route,
      Paint()
        ..color = navy
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(points.first, 10, Paint()..color = teal);
    canvas.drawCircle(points.last, 10, Paint()..color = orange);

    final lengths = <double>[];
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      final d = (points[i + 1] - points[i]).distance;
      lengths.add(d);
      total += d;
    }
    var target = total * t;
    var pos = points.first;
    for (var i = 0; i < lengths.length; i++) {
      if (target <= lengths[i]) {
        final f = lengths[i] == 0 ? 0.0 : target / lengths[i];
        pos = Offset.lerp(points[i], points[i + 1], f)!;
        break;
      }
      target -= lengths[i];
      pos = points[i + 1];
    }
    canvas.drawCircle(pos, 15, Paint()..color = navy);
    canvas.drawCircle(pos, 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(MapPainter old) => old.t != t;
}

void showCareDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Customer care'),
      content: const Text('Customer care is available from 9 AM to 10 PM. Add your support phone number here before launch.'),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
    ),
  );
}

// ---------------------------------------------------------------- orders, support, chat

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Your orders')),
          body: appState.orders.isEmpty
              ? const Center(child: Text('No orders yet. Pick a restaurant to start.', style: TextStyle(color: inkGrey)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final o in appState.orders)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => TrackingScreen(order: o)),
                          ),
                          title: Text('Order #${o.id} · ${o.restaurant.name}',
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(o.rejected
                              ? 'Rejected'
                              : (!o.autoAdvance ? 'Waiting for the restaurant' : stageNames[o.stage])),
                          trailing: Text('Rs. ${o.total}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class SupportTab extends StatelessWidget {
  const SupportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: navy),
              title: const Text('Chat support', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Message our team'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatScreen())),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.headset_mic, color: navy),
              title: const Text('Customer care', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Talk to us about your order'),
              onTap: () => showCareDialog(context),
            ),
          ),
          const DeveloperFooter(),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool mine;
  ChatMessage(this.text, this.mine);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final messages = <ChatMessage>[ChatMessage('Hello! How can we help you today?', false)];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() => messages.add(ChatMessage(text, true)));
    controller.clear();
    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => messages.add(ChatMessage('Thanks for your message. Our team will reply shortly.', false)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat support')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final m in messages)
                  Align(
                    alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: m.mine ? navy : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(m.text, style: TextStyle(color: m.mine ? Colors.white : Colors.black87)),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: controller, decoration: fieldStyle('Type a message'))),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: orange),
                    onPressed: send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- profile

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: Image.asset('assets/icon.png', width: 140, height: 140)),
          const SizedBox(height: 8),
          const Center(
            child: Text('Kamalpur Food Tracker', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: navy)),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.storefront, color: orange),
              title: const Text('Sell on Kamalpur Food Tracker', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Register your restaurant and add dishes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => appState.myRestaurant == null ? const SellerRegisterScreen() : const SellerHome(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              leading: Icon(Icons.info_outline, color: navy),
              title: Text('About', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(developerLine),
            ),
          ),
          const DeveloperFooter(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- seller

class SellerRegisterScreen extends StatefulWidget {
  const SellerRegisterScreen({super.key});

  @override
  State<SellerRegisterScreen> createState() => _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends State<SellerRegisterScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final fssai = TextEditingController();
  final cuisine = TextEditingController();
  String? photo;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    address.dispose();
    fssai.dispose();
    cuisine.dispose();
    super.dispose();
  }

  Future<void> pick(ImageSource source) async {
    final x = await ImagePicker().pickImage(source: source, maxWidth: 1200, imageQuality: 80);
    if (x != null) setState(() => photo = x.path);
  }

  void submit() {
    if (name.text.trim().isEmpty || phone.text.trim().length < 10 || fssai.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the restaurant name, a 10-digit phone number, and your FSSAI number')),
      );
      return;
    }
    appState.registerRestaurant(name.text.trim(), cuisine.text.trim(), photo);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SellerHome()));
  }

  Widget labeled(String label, TextEditingController c, String hint, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(controller: c, keyboardType: type, decoration: fieldStyle(hint)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register your restaurant')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Reach customers in Kamalpur. We review every application.', style: TextStyle(color: inkGrey)),
          const SizedBox(height: 16),
          labeled('Restaurant name', name, "Your restaurant's name"),
          labeled('Owner phone number', phone, '10-digit mobile number', type: TextInputType.phone),
          labeled('Address', address, 'Street, area, Kamalpur'),
          labeled('Cuisine', cuisine, 'North Indian, Chinese'),
          labeled('FSSAI license number', fssai, '14-digit license number', type: TextInputType.number),
          const Text('Restaurant photo', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF7A8899), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: photo != null
                ? Image.file(File(photo!), fit: BoxFit.cover, width: double.infinity)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => pick(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Camera'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          BigButton(label: 'Submit for approval', onTap: submit),
          const DeveloperFooter(),
        ],
      ),
    );
  }
}

class SellerHome extends StatelessWidget {
  const SellerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final r = appState.myRestaurant!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(r.name),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFD6E2F0),
            indicatorColor: orange,
            tabs: [Tab(text: 'Orders'), Tab(text: 'Menu')],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddItemScreen())),
          icon: const Icon(Icons.add),
          label: const Text('Add item'),
        ),
        body: const TabBarView(children: [SellerOrders(), SellerMenu()]),
      ),
    );
  }
}

class SellerOrders extends StatelessWidget {
  const SellerOrders({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final mine = appState.orders.where((o) => o.restaurant == appState.myRestaurant).toList();
        if (mine.isEmpty) {
          return const Center(child: Text('No orders yet.', style: TextStyle(color: inkGrey)));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final o in mine)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (!o.autoAdvance && !o.rejected) ? orange : Colors.white,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${o.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(o.lines.map((l) => '${l.item.name} x ${l.qty}').join(', '),
                        style: const TextStyle(color: inkGrey)),
                    const SizedBox(height: 4),
                    Text('${o.payment}  ·  Rs. ${o.total}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    if (o.rejected)
                      const Text('Rejected', style: TextStyle(color: Color(0xFFA32D2D), fontWeight: FontWeight.w800))
                    else if (!o.autoAdvance)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFA32D2D),
                                minimumSize: const Size(0, 48),
                              ),
                              onPressed: () => appState.rejectOrder(o),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: teal, minimumSize: const Size(0, 48)),
                              onPressed: () => appState.acceptOrder(o),
                              child: const Text('Accept'),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(stageNames[o.stage], style: const TextStyle(color: teal, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class SellerMenu extends StatelessWidget {
  const SellerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final items = appState.myRestaurant!.items;
        if (items.isEmpty) {
          return const Center(child: Text('Add your first dish with the Add item button.', style: TextStyle(color: inkGrey)));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            for (final i in items)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    FoodPhoto(path: i.photoPath, size: 64),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('Rs. ${i.price}', style: const TextStyle(color: navy, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    Switch(value: i.available, activeColor: teal, onChanged: (_) => appState.toggleAvailable(i)),
                    IconButton(
                      tooltip: 'Delete item',
                      onPressed: () => appState.removeMenuItem(i),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final name = TextEditingController();
  final price = TextEditingController();
  final category = TextEditingController();
  final desc = TextEditingController();
  bool available = true;
  String? photo;

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    category.dispose();
    desc.dispose();
    super.dispose();
  }

  Future<void> pick(ImageSource source) async {
    final x = await ImagePicker().pickImage(source: source, maxWidth: 1000, imageQuality: 80);
    if (x != null) setState(() => photo = x.path);
  }

  void save() {
    final p = int.tryParse(price.text.trim());
    if (name.text.trim().isEmpty || p == null || p <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the dish name and a price')),
      );
      return;
    }
    appState.addMenuItem(MenuItem(
      name: name.text.trim(),
      desc: desc.text.trim(),
      price: p,
      category: category.text.trim(),
      photoPath: photo,
      available: available,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add menu item')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Food photo', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF7A8899), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: photo != null
                ? Image.file(File(photo!), fit: BoxFit.cover, width: double.infinity)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo, size: 34, color: navy),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(onPressed: () => pick(ImageSource.camera), child: const Text('Camera')),
                          const SizedBox(width: 10),
                          OutlinedButton(onPressed: () => pick(ImageSource.gallery), child: const Text('Gallery')),
                        ],
                      ),
                    ],
                  ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Use a bright, square photo of the dish.', style: TextStyle(color: inkGrey, fontSize: 12)),
          ),
          const SizedBox(height: 14),
          const Text('Item name', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(controller: name, decoration: fieldStyle('Chicken biryani')),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Price (Rs.)', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(controller: price, keyboardType: TextInputType.number, decoration: fieldStyle('180')),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(controller: category, decoration: fieldStyle('Biryani')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Short description', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(controller: desc, decoration: fieldStyle('Served with raita')),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              title: const Text('Available now', style: TextStyle(fontWeight: FontWeight.w700)),
              value: available,
              activeColor: teal,
              onChanged: (v) => setState(() => available = v),
            ),
          ),
          const SizedBox(height: 20),
          BigButton(label: 'Save item', onTap: save),
          const DeveloperFooter(),
        ],
      ),
    );
  }
}
