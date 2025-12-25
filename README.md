# Kartazia - Developer Guide

## 🚀 Project Status: MVP Completed
The Kartazia mobile application has been fully implemented as a Flutter MVP (Minimum Viable Product). It features:
- **Child-Friendly UI**: Vibrant colors, animations, and simple navigation.
- **Secure Authentication**: Username/Password login (mapped to Supabase Auth using `@kartazia.app` domain wrapper).
- **Gamification**: XP, Levels, and Badges display.
- **Card Marketplace**: Browsing and requesting gift cards.
- **My Cards & Requests**: Realtime tracking of request status (Pending -> Paid -> Delivered).
- **Sharing**: Native share sheet to send payment links to parents.

## 🛠️ Setup Instructions

### 1. Supabase Backend
This app relies on a Supabase backend. You must perform the following steps if you haven't already:

1.  **Create Project**: Create a new Supabase project.
2.  **Run Schema**: Go to the SQL Editor in your Supabase dashboard and run the contents of `database_schema.sql` (located in the project root).
    *   *This helps set up Tables, RLS Policies, and Automatic Code Allocation logic.*
3.  **Enable Auth**:
    *   Go to **Authentication -> Providers**.
    *   Enable **Email/Password**.
    *   Disable "Confirm Email" (optional, for easier testing).
4.  **Insert Data**:
    *   Add some rows to the `cards` table so the marketplace isn't empty.
    *   Add some rows to the `codes` table (linked to `cards`) so there are codes to allocate.

### 2. Environment Variables
Open `lib/core/constants/supabase_constants.dart` and update the following with your keys from **Project Settings -> API**:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 3. Running the App
```bash
flutter pub get
flutter run
```

## 📱 Features Walkthrough

### 1. Authentication
- **Sign Up**: Enter a Username (e.g., `Hero1`) and Password. The app auto-generates a backend email (`Hero1@kartazia.app`).
- **Login**: Use the same credentials.

### 2. Requesting a Card
- Go to the **Marketplace** (Cards tab).
- Tap on a card -> Confirm Request.
- The request is saved to `card_requests` with status `pending`.

### 3. Parent Payment (Simulation)
- Go to **My Cards**.
- You will see the request is "Pending".
- Share the link (or copy the ID).
- **To Simulate Payment**:
    - Go to Supabase Dashboard -> Table Editor -> `card_requests`.
    - Find the row and change `status` to `paid`.
    - *The App will update instantly thanks to Realtime streams!*

## 📁 Project Structure
- `lib/features`: Contains all feature-specific code (Auth, Home, Cards, Profile).
- `lib/core`: Shared utilities and Theme.
- `lib/data`: Repositories and Models.

## 🔮 Future Improvements
- **Payment Gateway Integration**: Build the actual web page for `/pay/:id` using stripe.
- **Push Notifications**: Notify child when card is paid.
- **Admin Panel**: For managing cards and codes easily.
