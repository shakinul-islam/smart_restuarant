# 🍽️ Smart Restaurant Ordering System (SaaS)

A comprehensive, multi-tenant Software as a Service (SaaS) platform designed to digitalize restaurant operations. This system offers contactless QR-based ordering, real-time role-based push notifications, and a centralized management architecture capable of hosting multiple restaurants on a single robust backend.

## ✨ Core Features

### 🏢 Multi-Tenant SaaS Architecture
* **Data Isolation:** Seamlessly handles multiple restaurants using scalable `restaurant_id` tagging. One restaurant's data is completely invisible to others.
* **Super Admin Control (Kill Switch):** Global administrative powers to monitor tenants, broadcast platform-wide notices, and instantly block/unblock restaurant access based on subscription status.
* **Bootstrapped Billing:** Zero-commission subscription management utilizing a manual bKash validation system for optimal early-stage startup revenue.

### 👥 Role-Based Workspaces
* **Customer Web App:** Frictionless ordering experience. Customers scan dynamic table-specific QR codes to browse the menu and place orders directly via browser—no app installation required.
* **Kitchen Panel:** Receives instant push notifications for new orders (e.g., "Table 5 placed a new order") to begin prep immediately.
* **Waiter Panel:** Triggered alerts when food is ready to be served from the kitchen to the specific table.
* **Tenant Admin:** Dedicated dashboard for restaurant owners to manage digital menus, generate QR codes, and track daily sales.

### 🔒 Enterprise-Grade Security
* **Bulletproof Notification Proxy:** Implemented a custom Cloudflare Worker to bypass strict web CORS policies and securely encapsulate the OneSignal REST API Key, ensuring zero credential leakage in the frontend repository.

## 🛠️ Tech Stack

* **Frontend:** Flutter (Web & Android)
* **Database & Auth:** Firebase (Firestore, Firebase Authentication)
* **Real-time Push Notifications:** OneSignal
* **Serverless Proxy:** Cloudflare Workers (JavaScript)
1. **Clone the repository:**
   ```bash
   git clone [https://github.com/yourusername/smart-restaurant-saas.git](https://github.com/yourusername/smart-restaurant-saas.git)
