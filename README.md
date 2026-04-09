# ShelfSense — Modern Inventory & Point-of-Sale (POS) System

**ShelfSense** is a comprehensive, cloud-connected Flutter application designed to simplify inventory management and streamline the checkout experience for small to medium-sized businesses. It provides powerful tools for tracking products, processing sales (even offline), and reviewing detailed business analytics.

---

## 🚀 Key Features

### 1. Robust Authentication & Role-Based Access
* **Secure Login**: Built with Firebase Authentication.
* **Role Management**: Distinguishes between **Owner** and **Staff/Employee** roles. 
* **Custom Views**: Some features (like the Analytics Dashboard) are strictly locked to the 'Owner' role, while basic sales and scanning are available to all staff.

### 2. Live Dashboard Overview
* Gain an immediate visual summary of your store's performance.
* See daily sales totals, recent transaction feeds, and low-stock alerts at a glance.

### 3. Product & Inventory Management
* **Add/Edit Products**: Easily manage your catalog, including names, descriptions, pricing, and stock quantities.
* **Real-time Sync**: Changes to inventory are instantly synced across all devices connected to the store via Cloud Firestore.
* **Low Stock Tracking**: Automatically detect when items fall below a defined threshold to ensure you never run out of critical stock.

### 4. Barcode / QR Code Scanning
* **Fast Checkout**: Built-in camera scanner to quickly add items to a customer's cart during checkout.
* **Instant Lookups**: Scan a product on the shelf to instantly pull up its details, verify its price, or update stock levels without manual searching.

### 5. Point of Sale (POS) & Sales Tracking
* **Cart System**: Compile customer orders dynamically and process checkouts.
* **Automatic Receipt/Invoice Generation**: Keep organized records of every transaction.
* **Sales History**: View an ongoing chronological log of all completed sales, accessible whenever you need to process a return or verify a past transaction.

### 6. Offline Support & Syncing 
* **Work Without Internet**: Sometimes the Wi-Fi drops. ShelfSense uses local storage (`Hive` NoSQL database) to queue up your sales offline.
* **Auto-Sync**: The moment your device regains network connectivity, the app automatically syncs all queued, offline sales seamlessly to your Firebase database.

### 7. Advanced Analytics (Owner Only)
* Visual graphs breaking down revenue, top-selling products, and identifying sales trends over time.
* Empowers business owners to make data-driven decisions on purchasing and store workflow.

### 8. Customizable Settings
* Configure store details, manage employee accounts, and adjust app preferences directly from the settings menu.

---

## 🛠️ Architecture & Tech Stack

ShelfSense utilizes a modern, robust mobile stack:

* **Frontend Framework:** Flutter (Dart) — offering beautiful, compiled native experiences across iOS and Android.
* **State Management:** `Provider` — to efficiently manage auth state, product catalogs, and the live shopping cart.
* **Backend & Database:** Firebase —
  * **Firebase Authentication:** For secure user sign-ups and logins.
  * **Cloud Firestore:** A live, NoSQL database for syncing products and sales across devices in real-time.
* **Local Storage:** `Hive` — a lightweight and incredibly fast local database used for caching and saving offline transactions.
* **Connectivity Tracking:** Uses `connectivity_plus` to monitor network states and trigger background syncs when returning online.

---

## ⚙️ How It Works (The Core Workflow)

1. **Initialization**: On launch, the app verifies if the user is already authenticated. If so, they bypass the login screen. It simultaneously boots up the Hive local storage for edge-case offline tracking.
2. **Data Streaming**: Once logged in, the `ProductProvider` and `SalesProvider` attach listeners to Cloud Firestore. Any change in the database (e.g., another employee updating a price) reflects immediately on the UI.
3. **Transaction Flow**:
   * A staff member opens the **Scan** tab.
   * They scan items to add them to the checkout cart.
   * On completing the sale, the app attempts to push the transaction to Firestore and deducts inventory quantities.
   * *If offline*, the transaction is serialized and saved locally to Hive. 
4. **Offline Recovery**: The app constantly listens for network changes. When the network comes back online, a silent background routine automatically pushes the cached Hive transactions to Firebase and clears the local queue.

---

## 🚦 Getting Started & Setup

For instructions on configuring the Firebase backend to run the app yourself, refer to the [FIREBASE_SETUP.md](./FIREBASE_SETUP.md) file included in this repository.

To run the application locally:
```bash
# Get dependencies
flutter pub get

# Run the app
flutter run
```
