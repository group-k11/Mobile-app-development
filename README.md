# ShelfSense — Smart Inventory & Point-of-Sale App

**ShelfSense** is a Flutter application that connects to Firebase to provide real-time inventory tracking, intelligent stock alerts, barcode-based product lookup, and a complete checkout flow for small businesses.

---

## 🚀 Features

### 1. 📊 Dashboard — Sales Analytics & Smart Alerts
- Displays **today's live sales metrics**: Total Revenue, Total Profit, Items Sold, and Transaction Count — all streamed live from Firestore's `sales` collection.
- **Intelligent Stock Alerts**: Scans all products in real-time and surfaces per-product warnings:
  - 🔴 **Out of Stock** — quantity is 0
  - 🟠 **Threshold-based Stock Alert** — quantity is below 5
  - 🔵 **Reorder Recommended** — quantity is below 3
  - ⚫ **Inactivity-based Detection** — not sold in the last 30+ days
  - 🔴 **Expired** — expiry date is in the past
  - 🟠 **Expiring Soon** — expiry date is within 7 days

### 2. 📦 Product List
- Fetches and displays all products from Firestore, ordered alphabetically by name.
- Each product card shows: name, barcode, selling price, quantity, cost price, profit margin, expiry date, and smart status tags.
- Live-streaming via `StreamBuilder` — no manual refresh needed.

### 3. ➕ Add Product
- Form-based screen to add new products to the Firestore `products` collection.
- **Fields**: Product Name, Selling Price, Cost Price (optional), Barcode, Quantity, Expiry Date (optional date picker).
- Validates all required fields before saving.
- Automatically **prefills the barcode** if opened from the Scan screen after scanning an unknown barcode.

### 4. 📷 Barcode Scanner
- Uses the device camera (via `mobile_scanner`) to scan product barcodes.
- **If product is found in Firestore**: Displays a dialog with product details and an "Add to Cart" button.
- **If product is NOT found**: Prompts the user to add the new product, pre-filling the scanned barcode in the Add Product form.
- Shows "Product retrieved from database" confirmation on a successful lookup.

### 5. 🛒 Cart & Checkout
- Cart is a global in-memory list (`CartScreen.cartItems`) shared between the Scan and Cart screens.
- Displays all scanned items with individual prices and a running total + estimated profit.
- **Checkout flow**:
  1. Writes a new document to the Firestore `sales` collection (with total amount, profit, item count, timestamp).
  2. Decrements the `quantity` field for each sold product in Firestore.
  3. Updates `lastSoldDate` on each sold product (used by the inactivity alert).
  4. Shows a "Sale Complete!" confirmation dialog with the final total and profit.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart 3) |
| **Database** | Cloud Firestore (real-time streaming) |
| **Backend Init** | Firebase Core |
| **Barcode Scanning** | `mobile_scanner ^6.0.7` |
| **UI** | Material Design 3 |

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point, Firebase init, 5-tab navigation
└── screens/
    ├── dashboard_screen.dart    # Sales analytics + intelligent stock alerts
    ├── product_list_screen.dart # Full product list with status tags
    ├── add_product_screen.dart  # Add new product form
    ├── scan_screen.dart         # Camera barcode scanner + Firestore lookup
    └── cart_screen.dart         # Cart management + checkout + Firestore writes
```

---

## ⚙️ Firestore Data Model

### `products` collection
| Field | Type | Description |
|---|---|---|
| `name` | String | Product name |
| `price` | Number | Selling price |
| `costPrice` | Number | Purchase cost (for profit calculation) |
| `barcode` | String | Barcode string used for lookups |
| `quantity` | Number | Current stock level |
| `expiryDate` | Timestamp | Optional expiry date |
| `lastSoldDate` | Timestamp | Updated on every checkout |
| `createdAt` | Timestamp | Server-set creation time |

### `sales` collection
| Field | Type | Description |
|---|---|---|
| `totalAmount` | Number | Total sale value |
| `totalProfit` | Number | Total profit for this transaction |
| `itemCount` | Number | Number of items in the sale |
| `items` | Array | Snapshot of each sold item |
| `timestamp` | Timestamp | Server-set sale time |

---

## 🚦 Getting Started

### Prerequisites
- Flutter SDK (`^3.11.1`)
- A Firebase project with **Cloud Firestore** enabled
- Place your `google-services.json` (Android) in `android/app/`

### Run the app
```powershell
# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```
