# Kartazia - Implementation Plan

## Project Overview
**App Name:** Kartazia
**Language:** Arabic (RTL)
**Target:** Kids (Gamified UI) & Parents (Secure Payments)
**Tech Stack:** Flutter (Android First), Supabase (Auth, DB, Realtime).

## 1. Project Setup & Architecture
- **Command:** `flutter create . --org com.kartazia --project-name kartazia`
- **Architecture:** Clean Architecture
  - `lib/core`: Utils, Constants, Theme, Error handling.
  - `lib/features`: Feature-based modular structure (e.g., `auth`, `home`, `cards`, `profile`).
    - `data`: Models, Repositories (Impl), Data Sources.
    - `domain`: Entities, Repositories (Interfaces), UseCases.
    - `presentation`: Pages, Widgets, Providers/Controllers.

## 2. Supabase Database Design (SQL)
*To be executed in Supabase SQL Editor*
- **Tables:**
  - `users`: Profile data (avatar, XP, role).
  - `cards`: Gift card tailored data (name, image, price, xp_reward).
  - `card_requests`: Child requests (status: pending, paid, delivered).
  - `codes`: Actual gift codes (protected by RLS).
  - `xp_transactions`: History of XP earnings.
  - `badges`: Available badges.
  - `user_badges`: Badges won by users.
- **Security (RLS):**
  - Strict policies ensuring kids only see their own requests and *never* see codes unless paid.
  - Parents access via public link (handled via unique request ID).

## 3. Core Features Implementation
### A. Theme & UI (Crucial for "Wow" factor)
- **Colors:** Vibrant, child-friendly (Yellows, Blues, Purples).
- **Typography:** Rounded Arabic font (e.g., Almarai or Tajawal).
- **Animations:** `flutter_animate` for fade-ins, scales, and unlocks.

### B. Navigation & Routing
- Bottom Navigation Bar (Curved/Rounded).
- Routes: Splash -> Auth/Home -> Details.

### C. Features
1.  **Splash Screen:** Animated fade-in.
2.  **Home (الرئيسية):** User stats, XP bar, Quick actions.
3.  **Marketplace (كل البطاقات):** Grid of cards with filters.
4.  **My Cards (بطاقاتي):** Status tracking (Pending -> Paid -> Delivered).
5.  **Rewards (المكافآت):** XP redemption.
6.  **Profile (ملفي):** Avatar and stats.

## 4. Payment & Code Allocation Logic
- **Child flow:** Select Card -> Create `card_request` (pending).
- **Parent flow:** Open `/pay/:requestId` (Web view or external browser).
- **Backend Logic (Supabase Edge Function / Triggers):**
  - Listen for payment success.
  - Atomic transaction: Pick 1 available code -> Assign to request -> Mark request paid -> Mark code used.

## 5. Dependencies
- `flutter_riverpod` (State Management)
- `supabase_flutter`
- `go_router`
- `flutter_animate`
- `google_fonts`
- `intl`
- `uni_links` (Deep linking for payment return)

## Execution Steps
1.  [x] Initialize Flutter Project.
2.  [x] Add dependencies.
3.  [x] Setup clean architecture folder structure.
4.  [x] Create Database Schema file (for reference).
5.  [x] Implement Theme & Core Widgets (Splash, Home Shell, Card Item).
6.  [x] Build Screens one by one (Splash -> Home -> Cards connected to Mock/Supabase Repos).
7.  [x] Implement 'My Cards' Page & Request Logic.
8.  [x] Implement Rewards & Profile Pages.
9.  [x] Implement Authentication (Login/Signup).
10. [x] Integrate Realtime Updates & Sharing.
11. [x] Final Polish (User Stats, Navigation, UI Connect).
