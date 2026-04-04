# Better You — Apple App Privacy Nutrition Labels

Draft for App Store Connect submission. Based on full codebase audit of data collection.

## How to fill in App Store Connect

Go to App Store Connect > Your App > App Privacy > Get Started.

---

## Data Types Collected

### 1. Contact Info

**Email Address**
- Collected: YES
- Purpose: **App Functionality** (authentication via Supabase)
- Linked to User Identity: YES
- Used for Tracking: NO

### 2. Identifiers

**User ID**
- Collected: YES (Supabase UUID)
- Purpose: **App Functionality** (account management, data sync)
- Linked to User Identity: YES
- Used for Tracking: NO

**Device ID** (APNs token)
- Collected: YES
- Purpose: **App Functionality** (push notifications for habit reminders)
- Linked to User Identity: YES
- Used for Tracking: NO

### 3. Usage Data

**Product Interaction**
- Collected: YES (PostHog analytics — 22 events)
- Purpose: **Analytics** (understand feature usage, funnel optimization)
- Linked to User Identity: YES (via PostHog distinct_id)
- Used for Tracking: NO

### 4. Purchases

**Purchase History**
- Collected: YES (via RevenueCat)
- Purpose: **App Functionality** (manage Pro subscription, trial status)
- Linked to User Identity: YES
- Used for Tracking: NO

### 5. User Content

**Other User Content** (habit names, coach messages, identity traits, reflection responses)
- Collected: YES
- Purpose: **App Functionality** (core habit tracking, AI coaching)
- Linked to User Identity: YES
- Used for Tracking: NO

---

## Data Types NOT Collected

Check "No" for all of these:

- [ ] Health & Fitness
- [ ] Financial Info
- [ ] Location (precise or coarse)
- [ ] Sensitive Info
- [ ] Contacts
- [ ] Browsing History
- [ ] Search History
- [ ] Photos or Videos
- [ ] Audio Data
- [ ] Gameplay Content
- [ ] Customer Support
- [ ] Physical Address
- [ ] Phone Number
- [ ] Name (collected but optional — check with Apple if this needs to be declared)
- [ ] Advertising Data
- [ ] Diagnostics (crash logs) — check if PostHog collects these automatically

---

## Third-Party SDKs and Their Data Collection

### PostHog (Analytics)
- Events: 22 custom events (habit_completed, paywall_shown, etc.)
- Properties: event-specific (habit_name, plan type, etc.)
- Automatic: device type, OS version, app version, session data
- NOT shared for advertising
- Privacy: PostHog is self-hosted OR EU-hosted depending on config

### RevenueCat (Purchases)
- Purchase events, subscription status, trial dates
- App User ID mapped to Supabase UUID
- Revenue data
- Privacy: RevenueCat acts as a data processor, not controller

### Anthropic Claude API (AI Coach)
- User's coach messages (text content)
- Habit names, streaks, completion status (for context)
- Identity traits selected during onboarding
- NOT: email, user ID, or other PII
- Privacy: Anthropic does not train on API data per their terms

### Supabase (Backend)
- All persistent user data (habits, logs, streaks, profile)
- Auth data (email, password hash, sessions)
- Privacy: Supabase acts as infrastructure provider

---

## App Tracking Transparency

**ATT prompt required?** NO

We do not:
- Use IDFA
- Track users across other companies' apps or websites
- Share data with data brokers
- Use third-party advertising SDKs

---

## IMPORTANT: Camera Permission Issue

**Action required before submission:**

Info.plist declares `NSCameraUsageDescription: "Used for profile photos"` but no camera functionality exists in the app. Apple WILL reject for this.

**Fix:** Remove the `NSCameraUsageDescription` key from Info.plist, OR implement profile photo functionality.

Recommendation: Remove it. Profile photos are not part of the MVP.

File: `HabitStack/Info.plist` (lines 32-33)
