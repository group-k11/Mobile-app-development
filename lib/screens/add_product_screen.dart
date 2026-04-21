import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// This screen lets the user type in product details and save them to Firebase.
// It can receive a barcode from the scan screen (optional).
class AddProductScreen extends StatefulWidget {
  final String? prefilledBarcode;

  const AddProductScreen({super.key, this.prefilledBarcode});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  // Controllers let us read what the user typed in each text field
  final _nameController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _quantityController = TextEditingController();

  DateTime? _expiryDate; // Will be null if user didn't pick a date
  bool _isLoading = false; // Shows a spinner on the button while saving

  @override
  void initState() {
    super.initState();
    // If a barcode was scanned before coming here, fill it in automatically
    if (widget.prefilledBarcode != null) {
      _barcodeController.text = widget.prefilledBarcode!;
    }
  }

  @override
  void dispose() {
    // Always clean up controllers when the screen is closed
    _nameController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // Opens a calendar popup so the user can pick an expiry date
  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  // Shows a red error message at the bottom of the screen
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Reads all the fields, validates them, and saves to Firestore
  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final barcode = _barcodeController.text.trim();
    final sellingPrice = double.tryParse(_sellingPriceController.text.trim());
    final costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0;
    final quantity = int.tryParse(_quantityController.text.trim());

    // Check that all required fields are filled
    if (name.isEmpty || barcode.isEmpty) {
      _showError('Please fill in name and barcode');
      return;
    }
    if (sellingPrice == null || sellingPrice <= 0) {
      _showError('Enter a valid selling price');
      return;
    }
    if (quantity == null || quantity < 0) {
      _showError('Enter a valid quantity');
      return;
    }

    // Show loading spinner
    setState(() => _isLoading = true);

    try {
      // Save the product as a new document in the "products" collection
      await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'price': sellingPrice,
        'costPrice': costPrice,
        'barcode': barcode,
        'quantity': quantity,
        'expiryDate': _expiryDate != null
            ? Timestamp.fromDate(_expiryDate!)
            : null,
        'lastSoldDate': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return; // Safety check after async gap

      // Clear all fields after saving
      _nameController.clear();
      _sellingPriceController.clear();
      _costPriceController.clear();
      _barcodeController.clear();
      _quantityController.clear();
      setState(() => _expiryDate = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // If we came from the scan screen, go back after saving
      if (widget.prefilledBarcode != null) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error saving product: $e');
    }

    setState(() => _isLoading = false);
  }

  // A reusable helper to avoid repeating TextField code for every field
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format the expiry date nicely, or show a placeholder
    final expiryLabel = _expiryDate != null
        ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
        : 'Tap to select expiry date';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.prefilledBarcode != null ? 'Add Scanned Product' : 'Add Product',
        ),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Show a blue info banner only when a barcode was pre-scanned
            if (widget.prefilledBarcode != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Barcode prefilled from scan. Fill in the rest.',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

            _buildField(
              controller: _nameController,
              label: 'Product Name *',
              icon: Icons.label,
            ),
            const SizedBox(height: 16),

            // Two price fields side by side
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _sellingPriceController,
                    label: 'Selling Price (₹) *',
                    icon: Icons.sell,
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _costPriceController,
                    label: 'Cost Price (₹)',
                    icon: Icons.money_off,
                    isNumber: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildField(
              controller: _barcodeController,
              label: 'Barcode *',
              icon: Icons.qr_code,
            ),
            const SizedBox(height: 16),

            _buildField(
              controller: _quantityController,
              label: 'Quantity *',
              icon: Icons.inventory_2,
              isNumber: true,
            ),
            const SizedBox(height: 16),

            // Expiry date — tap to open calendar, tap X to clear
            OutlinedButton.icon(
              onPressed: _pickExpiryDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(expiryLabel),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                alignment: Alignment.centerLeft,
              ),
            ),
            if (_expiryDate != null)
              TextButton.icon(
                onPressed: () => setState(() => _expiryDate = null),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear expiry date'),
              ),
            const SizedBox(height: 24),

            // Save button — shows a spinner while saving
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProduct,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Save Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A5F),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
