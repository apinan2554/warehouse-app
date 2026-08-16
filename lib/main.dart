import 'package:flutter/material.dart';

void main() {
  runApp(const WarehouseApp());
}

const List<String> productCategories = [
  'ไฟฟ้า',
  'Accessory',
  'อิเล็กทรอนิกส์',
  'พลาสติก',
];

class Product {
  final String id;
  String name;
  String unit;
  String category;
  String description;
  int reorderPoint;
  Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.category,
    this.description = '',
    this.reorderPoint = 0,
  });
}

class StockEntry {
  final String productId;
  final String zone;
  int quantity;
  StockEntry({required this.productId, required this.zone, required this.quantity});
}

class TransactionLog {
  final String type;
  final String productId;
  final String fromZone;
  final String toZone;
  final int quantity;
  final DateTime timestamp;
  TransactionLog({
    required this.type,
    required this.productId,
    this.fromZone = '',
    this.toZone = '',
    required this.quantity,
    required this.timestamp,
  });
}

class DataStore {
  static final DataStore _instance = DataStore._internal();
  factory DataStore() => _instance;
  DataStore._internal();

  final List<Product> products = [];
  final List<StockEntry> stock = [];
  final List<TransactionLog> logs = [];
  final List<String> mainZones = ['Zone A', 'Zone B', 'Zone C'];
  final List<String> zones = [
    'A1', 'A2', 'A3',
    'B1', 'B2', 'B3',
    'C1', 'C2', 'C3',
  ];
  final String warehouseName = 'Main Warehouse';

  List<String> subZonesOf(String mainZone) {
    final prefix = mainZone.split(' ').last;
    return zones.where((z) => z.startsWith(prefix)).toList();
  }

  int getStock(String productId, String zone) {
    final found = stock.where((s) => s.productId == productId && s.zone == zone);
    return found.isEmpty ? 0 : found.first.quantity;
  }

  void addStock(String productId, String zone, int qty) {
    final idx = stock.indexWhere((s) => s.productId == productId && s.zone == zone);
    if (idx >= 0) {
      stock[idx].quantity += qty;
    } else {
      stock.add(StockEntry(productId: productId, zone: zone, quantity: qty));
    }
  }

  bool reduceStock(String productId, String zone, int qty) {
    final idx = stock.indexWhere((s) => s.productId == productId && s.zone == zone);
    if (idx < 0 || stock[idx].quantity < qty) return false;
    stock[idx].quantity -= qty;
    if (stock[idx].quantity == 0) stock.removeAt(idx);
    return true;
  }

  int get totalStock => stock.fold(0, (sum, s) => sum + s.quantity);

  int stockByMainZone(String mainZone) {
    final prefix = mainZone.split(' ').last;
    return stock.where((s) => s.zone.startsWith(prefix)).fold(0, (sum, s) => sum + s.quantity);
  }

  int stockByZone(String zone) =>
      stock.where((s) => s.zone == zone).fold(0, (sum, s) => sum + s.quantity);

  String productName(String id) {
    final found = products.where((p) => p.id == id);
    return found.isEmpty ? id : found.first.name;
  }

  int totalStockOf(String productId) {
    return stock.where((s) => s.productId == productId).fold(0, (sum, s) => sum + s.quantity);
  }

  List<Product> productsInZone(String zone) {
    final ids = stock.where((s) => s.zone == zone && s.quantity > 0).map((s) => s.productId).toSet();
    return products.where((p) => ids.contains(p.id)).toList();
  }
}

class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warehouse Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;
  final _pages = const <Widget>[
    DashboardPage(),
    ProductMasterPage(),
    WarehouseZonePage(),
    InboundPage(),
    StockTransferPage(),
    OutboundPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 600) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            selectedIndex: _idx,
            onDestinationSelected: (i) => setState(() => _idx = i),
            labelType: width >= 800
                ? NavigationRailLabelType.all
                : NavigationRailLabelType.selected,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.warehouse, size: 32, color: Colors.blueGrey),
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Products')),
              NavigationRailDestination(icon: Icon(Icons.warehouse_outlined), selectedIcon: Icon(Icons.warehouse), label: Text('Zones')),
              NavigationRailDestination(icon: Icon(Icons.move_to_inbox_outlined), selectedIcon: Icon(Icons.move_to_inbox), label: Text('Inbound')),
              NavigationRailDestination(icon: Icon(Icons.swap_horiz_outlined), selectedIcon: Icon(Icons.swap_horiz), label: Text('Transfer')),
              NavigationRailDestination(icon: Icon(Icons.outbox_outlined), selectedIcon: Icon(Icons.outbox), label: Text('Outbound')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_idx]),
        ]),
      );
    }
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.warehouse_outlined), label: 'Zones'),
          NavigationDestination(icon: Icon(Icons.move_to_inbox_outlined), label: 'Inbound'),
          NavigationDestination(icon: Icon(Icons.swap_horiz_outlined), label: 'Transfer'),
          NavigationDestination(icon: Icon(Icons.outbox_outlined), label: 'Outbound'),
        ],
      ),
    );
  }
}

// Dashboard
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _s = DataStore();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final crossCount = width > 900 ? 4 : width > 500 ? 4 : 2;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('สรุปจำนวนสินค้าในคลัง', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: crossCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _summaryCard('สินค้าทั้งหมด', _s.totalStock, Colors.blueGrey),
                _summaryCard('Zone A', _s.stockByMainZone('Zone A'), Colors.blue),
                _summaryCard('Zone B', _s.stockByMainZone('Zone B'), Colors.teal),
                _summaryCard('Zone C', _s.stockByMainZone('Zone C'), Colors.indigo),
              ],
            ),
            const SizedBox(height: 24),
            Text('สินค้าที่ลงทะเบียน: ${_s.products.length} รายการ'),
            Text('ประวัติทำรายการ: ${_s.logs.length} รายการ'),
            const SizedBox(height: 16),
            if (_s.products.any((p) => p.reorderPoint > 0 && _s.totalStockOf(p.id) <= p.reorderPoint)) ...[
              Text('⚠️ สินค้าต่ำกว่าจุด Reorder', style: theme.textTheme.titleMedium?.copyWith(color: Colors.orange)),
              const SizedBox(height: 8),
              ..._s.products
                  .where((p) => p.reorderPoint > 0 && _s.totalStockOf(p.id) <= p.reorderPoint)
                  .map((p) => Card(
                        color: Colors.orange.shade50,
                        child: ListTile(
                          leading: const Icon(Icons.warning, color: Colors.orange),
                          title: Text(p.name),
                          subtitle: Text('คงเหลือ: ${_s.totalStockOf(p.id)} | Reorder: ${p.reorderPoint}'),
                        ),
                      )),
            ],
            const Spacer(),
            Center(
              child: FilledButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
                label: const Text('รีเฟรช'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, int value, Color color) => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              FittedBox(child: Text('$value', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color))),
              const Text('หน่วย', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );
}

// Product Master
class ProductMasterPage extends StatefulWidget {
  const ProductMasterPage({super.key});
  @override
  State<ProductMasterPage> createState() => _ProductMasterPageState();
}

class _ProductMasterPageState extends State<ProductMasterPage> {
  final _s = DataStore();
  final _idC = TextEditingController();
  final _nameC = TextEditingController();
  final _unitC = TextEditingController();
  final _descC = TextEditingController();
  final _reorderC = TextEditingController();
  String _cat = productCategories.first;

  void _add() {
    final id = _idC.text.trim();
    final name = _nameC.text.trim();
    final unit = _unitC.text.trim();
    if (id.isEmpty || name.isEmpty || unit.isEmpty) {
      _snack('กรุณากรอกข้อมูลให้ครบ');
      return;
    }
    if (_s.products.any((p) => p.id == id)) {
      _snack('รหัส "$id" มีอยู่แล้ว');
      return;
    }
    final reorder = int.tryParse(_reorderC.text.trim()) ?? 0;
    setState(() => _s.products.add(Product(
          id: id, name: name, unit: unit, category: _cat,
          description: _descC.text.trim(), reorderPoint: reorder)));
    _idC.clear(); _nameC.clear(); _unitC.clear(); _descC.clear(); _reorderC.clear();
    _snack('เพิ่ม "$name" สำเร็จ');
  }

  void _del(int i) {
    final p = _s.products[i];
    setState(() {
      _s.products.removeAt(i);
      _s.stock.removeWhere((s) => s.productId == p.id);
    });
    _snack('ลบ "${p.name}" แล้ว');
  }

  void _edit(int i) {
    final p = _s.products[i];
    final nameC = TextEditingController(text: p.name);
    final unitC = TextEditingController(text: p.unit);
    final descC = TextEditingController(text: p.description);
    final reorderC = TextEditingController(text: p.reorderPoint.toString());
    String cat = p.category;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('แก้ไข: ${p.id}'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width > 600 ? 400 : double.maxFinite,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'ชื่อสินค้า', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: cat,
                  decoration: const InputDecoration(labelText: 'ประเภท', border: OutlineInputBorder()),
                  items: productCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setD(() => cat = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: unitC, decoration: const InputDecoration(labelText: 'หน่วยนับ', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: reorderC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reorder Point', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: descC, decoration: const InputDecoration(labelText: 'รายละเอียด', border: OutlineInputBorder())),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            FilledButton(
              onPressed: () {
                setState(() {
                  p.name = nameC.text.trim();
                  p.unit = unitC.text.trim();
                  p.category = cat;
                  p.description = descC.text.trim();
                  p.reorderPoint = int.tryParse(reorderC.text.trim()) ?? 0;
                });
                Navigator.pop(ctx);
                _snack('แก้ไข "${p.name}" สำเร็จ');
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 2)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Master', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('เพิ่ม/แก้ไข/ลบ ข้อมูลสินค้า', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isNarrow ? _buildFormNarrow() : _buildFormWide(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _s.products.isEmpty
                  ? const Center(child: Text('ยังไม่มีสินค้า'))
                  : ListView.builder(
                      itemCount: _s.products.length,
                      itemBuilder: (_, i) {
                        final p = _s.products[i];
                        final totalQty = _s.totalStockOf(p.id);
                        final isLow = p.reorderPoint > 0 && totalQty <= p.reorderPoint;
                        return Card(
                          color: isLow ? Colors.orange.shade50 : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isLow ? Colors.orange : null,
                              child: Text(p.id, style: TextStyle(fontSize: 11, color: isLow ? Colors.white : null)),
                            ),
                            title: Text(p.name),
                            subtitle: Text('${p.category} | ${p.unit} | Reorder: ${p.reorderPoint} | Stock: $totalQty${isLow ? " ⚠️" : ""}'),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _edit(i)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _del(i)),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormNarrow() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _idC, decoration: const InputDecoration(labelText: 'รหัส', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _nameC, decoration: const InputDecoration(labelText: 'ชื่อสินค้า', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _cat,
            decoration: const InputDecoration(labelText: 'ประเภท', border: OutlineInputBorder()),
            items: productCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _cat = v!),
          ),
          const SizedBox(height: 10),
          TextField(controller: _unitC, decoration: const InputDecoration(labelText: 'หน่วยนับ', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _reorderC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reorder Point', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _descC, decoration: const InputDecoration(labelText: 'รายละเอียด', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('เพิ่มสินค้า')),
        ],
      );

  Widget _buildFormWide() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: 120, child: TextField(controller: _idC, decoration: const InputDecoration(labelText: 'รหัส', border: OutlineInputBorder()))),
              SizedBox(width: 160, child: TextField(controller: _nameC, decoration: const InputDecoration(labelText: 'ชื่อสินค้า', border: OutlineInputBorder()))),
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String>(
                  value: _cat,
                  decoration: const InputDecoration(labelText: 'ประเภท', border: OutlineInputBorder()),
                  items: productCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _cat = v!),
                ),
              ),
              SizedBox(width: 100, child: TextField(controller: _unitC, decoration: const InputDecoration(labelText: 'หน่วยนับ', border: OutlineInputBorder()))),
              SizedBox(width: 130, child: TextField(controller: _reorderC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reorder Point', border: OutlineInputBorder()))),
              SizedBox(width: 180, child: TextField(controller: _descC, decoration: const InputDecoration(labelText: 'รายละเอียด', border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('เพิ่มสินค้า')),
        ],
      );
}

// Warehouse & Zone
class WarehouseZonePage extends StatefulWidget {
  const WarehouseZonePage({super.key});
  @override
  State<WarehouseZonePage> createState() => _WarehouseZonePageState();
}

class _WarehouseZonePageState extends State<WarehouseZonePage> {
  final _s = DataStore();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Warehouse & Zone', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('ผังคลังสินค้าและโซนจัดเก็บ', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.warehouse, size: 40, color: Colors.blueGrey),
                title: Text(_s.warehouseName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: const Text('คลังสินค้าหลัก | 3 โซนหลัก | 9 โซนย่อย'),
              ),
            ),
            const SizedBox(height: 16),
            ..._s.mainZones.map((mz) {
              final color = mz == 'Zone A' ? Colors.blue : mz == 'Zone B' ? Colors.teal : Colors.indigo;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: Icon(Icons.grid_view, color: color, size: 36),
                  title: Text(mz, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  subtitle: Text('รวม: ${_s.stockByMainZone(mz)} หน่วย'),
                  children: _s.subZonesOf(mz).map((sub) => ListTile(
                    leading: const SizedBox(width: 36),
                    title: Text('โซนย่อย $sub'),
                    trailing: Chip(label: Text('${_s.stockByZone(sub)} หน่วย')),
                  )).toList(),
                ),
              );
            }),
            const SizedBox(height: 8),
            Center(child: FilledButton.icon(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh), label: const Text('รีเฟรช'))),
          ]),
        ),
      ),
    );
  }
}

// Inbound
class InboundPage extends StatefulWidget {
  const InboundPage({super.key});
  @override
  State<InboundPage> createState() => _InboundPageState();
}

class _InboundPageState extends State<InboundPage> {
  final _s = DataStore();
  String? _prodId;
  String _zone = 'A1';
  final _qtyC = TextEditingController();

  void _receive() {
    if (_prodId == null) { _snack('กรุณาเลือกสินค้า'); return; }
    final qty = int.tryParse(_qtyC.text.trim()) ?? 0;
    if (qty <= 0) { _snack('กรุณาระบุจำนวนที่มากกว่า 0'); return; }
    setState(() {
      _s.addStock(_prodId!, _zone, qty);
      _s.logs.add(TransactionLog(type: 'inbound', productId: _prodId!, toZone: _zone, quantity: qty, timestamp: DateTime.now()));
    });
    _qtyC.clear();
    _snack('รับ "${_s.productName(_prodId!)}" $qty หน่วย เข้า $_zone สำเร็จ');
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 2)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Inbound / Receiving', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('รับสินค้าเข้าคลัง', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                DropdownButtonFormField<String>(
                  value: _prodId,
                  decoration: const InputDecoration(labelText: 'เลือกสินค้า', border: OutlineInputBorder()),
                  items: _s.products.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.id} - ${p.name}'))).toList(),
                  onChanged: (v) => setState(() => _prodId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _zone,
                  decoration: const InputDecoration(labelText: 'เลือกโซน', border: OutlineInputBorder()),
                  items: _s.zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                  onChanged: (v) => setState(() => _zone = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: _qtyC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'จำนวน', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                FilledButton.icon(onPressed: _s.products.isEmpty ? null : _receive, icon: const Icon(Icons.move_to_inbox), label: const Text('รับสินค้าเข้าคลัง')),
                if (_s.products.isEmpty)
                  const Padding(padding: EdgeInsets.only(top: 8), child: Text('* เพิ่มสินค้าใน Product Master ก่อน', style: TextStyle(color: Colors.orange))),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          Text('สรุปสินค้าในแต่ละโซนหลัก', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._s.mainZones.map((mz) {
            final color = mz == 'Zone A' ? Colors.blue : mz == 'Zone B' ? Colors.teal : Colors.indigo;
            final total = _s.stockByMainZone(mz);
            return Card(
              child: ListTile(
                leading: Icon(Icons.grid_view, color: color),
                title: Text(mz, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                trailing: Text('$total หน่วย', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ),
            );
          }),
        ]),
      ),
    );
  }
}

// Stock Transfer
class StockTransferPage extends StatefulWidget {
  const StockTransferPage({super.key});
  @override
  State<StockTransferPage> createState() => _StockTransferPageState();
}

class _StockTransferPageState extends State<StockTransferPage> {
  final _s = DataStore();
  String _from = 'A1';
  String _to = 'B1';
  String? _prodId;
  final _qtyC = TextEditingController();

  List<Product> get _available => _s.productsInZone(_from);

  void _transfer() {
    if (_prodId == null) { _snack('กรุณาเลือกสินค้า'); return; }
    if (_from == _to) { _snack('โซนต้นทางและปลายทางต้องไม่เหมือนกัน'); return; }
    final qty = int.tryParse(_qtyC.text.trim()) ?? 0;
    if (qty <= 0) { _snack('กรุณาระบุจำนวนที่มากกว่า 0'); return; }
    final avail = _s.getStock(_prodId!, _from);
    if (qty > avail) { _snack('มีเพียง $avail หน่วย'); return; }
    setState(() {
      _s.reduceStock(_prodId!, _from, qty);
      _s.addStock(_prodId!, _to, qty);
      _s.logs.add(TransactionLog(type: 'transfer', productId: _prodId!, fromZone: _from, toZone: _to, quantity: qty, timestamp: DateTime.now()));
    });
    _qtyC.clear();
    final name = _s.productName(_prodId!);
    setState(() => _prodId = null);
    _snack('ย้าย "$name" $qty หน่วย $_from → $_to สำเร็จ');
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 2)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Stock Transfer', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('ย้ายสินค้าระหว่างโซน', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                DropdownButtonFormField<String>(
                  value: _from,
                  decoration: const InputDecoration(labelText: 'โซนต้นทาง', border: OutlineInputBorder()),
                  items: _s.zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                  onChanged: (v) => setState(() { _from = v!; _prodId = null; }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _prodId,
                  decoration: const InputDecoration(labelText: 'สินค้า (ที่มีในโซนต้นทาง)', border: OutlineInputBorder()),
                  items: _available.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.id} - ${p.name} (${_s.getStock(p.id, _from)})'))).toList(),
                  onChanged: (v) => setState(() => _prodId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _to,
                  decoration: const InputDecoration(labelText: 'โซนปลายทาง', border: OutlineInputBorder()),
                  items: _s.zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                  onChanged: (v) => setState(() => _to = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: _qtyC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'จำนวนที่ย้าย', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                FilledButton.icon(onPressed: _available.isEmpty ? null : _transfer, icon: const Icon(Icons.swap_horiz), label: const Text('ย้ายสินค้า')),
                if (_available.isEmpty)
                  const Padding(padding: EdgeInsets.only(top: 8), child: Text('* ไม่มีสินค้าในโซนต้นทาง', style: TextStyle(color: Colors.orange))),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// Outbound
class OutboundPage extends StatefulWidget {
  const OutboundPage({super.key});
  @override
  State<OutboundPage> createState() => _OutboundPageState();
}

class _OutboundPageState extends State<OutboundPage> {
  final _s = DataStore();
  String _zone = 'A1';
  String? _prodId;
  final _qtyC = TextEditingController();

  List<Product> get _available => _s.productsInZone(_zone);

  void _issue() {
    if (_prodId == null) { _snack('กรุณาเลือกสินค้า'); return; }
    final qty = int.tryParse(_qtyC.text.trim()) ?? 0;
    if (qty <= 0) { _snack('กรุณาระบุจำนวนที่มากกว่า 0'); return; }
    final avail = _s.getStock(_prodId!, _zone);
    if (qty > avail) { _snack('มีเพียง $avail หน่วย (ไม่พอจ่าย)'); return; }
    setState(() {
      _s.reduceStock(_prodId!, _zone, qty);
      _s.logs.add(TransactionLog(type: 'outbound', productId: _prodId!, fromZone: _zone, quantity: qty, timestamp: DateTime.now()));
    });
    _qtyC.clear();
    final name = _s.productName(_prodId!);
    setState(() => _prodId = null);
    _snack('จ่าย "$name" $qty หน่วย ออกจาก $_zone สำเร็จ');
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 2)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outLogs = _s.logs.where((l) => l.type == 'outbound').toList().reversed.take(10);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Outbound / Issuing', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('จ่ายสินค้าออกจากคลัง', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                DropdownButtonFormField<String>(
                  value: _zone,
                  decoration: const InputDecoration(labelText: 'เลือกโซน', border: OutlineInputBorder()),
                  items: _s.zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                  onChanged: (v) => setState(() { _zone = v!; _prodId = null; }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _prodId,
                  decoration: const InputDecoration(labelText: 'สินค้า (ที่มีในโซน)', border: OutlineInputBorder()),
                  items: _available.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.id} - ${p.name} (คงเหลือ ${_s.getStock(p.id, _zone)})'))).toList(),
                  onChanged: (v) => setState(() => _prodId = v),
                ),
                const SizedBox(height: 12),
                TextField(controller: _qtyC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'จำนวนที่จ่ายออก', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                FilledButton.icon(onPressed: _available.isEmpty ? null : _issue, icon: const Icon(Icons.outbox), label: const Text('จ่ายสินค้าออก')),
                if (_available.isEmpty)
                  const Padding(padding: EdgeInsets.only(top: 8), child: Text('* ไม่มีสินค้าในโซนนี้', style: TextStyle(color: Colors.orange))),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          Text('ประวัติจ่ายออกล่าสุด', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: outLogs.map((l) => ListTile(
                leading: const Icon(Icons.outbox, color: Colors.red),
                title: Text(_s.productName(l.productId)),
                subtitle: Text('จำนวน ${l.quantity} | จาก ${l.fromZone} | ${l.timestamp.toString().substring(0, 16)}'),
              )).toList(),
            ),
          ),
        ]),
      ),
    );
  }
}
