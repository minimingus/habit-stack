# Testing Guidelines

## iOS Version Targeting

### Do I need to test all iOS versions?

No. Set a **minimum deployment target** and test strategically:

**Minimum viable approach:**
- Pick a minimum deployment target (e.g., iOS 15, 16, or 17) based on market data and feature needs
- Test on that minimum version and the latest version
- Skip intermediate versions — iOS maintains strong backward compatibility

**What drives your choice:**

- **Market share** — Check App Analytics / App Store Connect to see what your users actually run. If 95%+ are on iOS 16+, targeting iOS 15 adds overhead for minimal gain.
- **Features you need** — SwiftUI, async/await, and framework APIs vary by version. Your minimum target is dictated by the lowest API you rely on.
- **Dependencies** — Supabase, RevenueCat, and other SDKs have their own minimums. Check their docs before choosing a target.

**Testing reality:**
- Test on minimum target (simulator + real device if possible)
- Test on latest (simulator + real device)
- Spot-check 1–2 intermediate versions only if you hit a specific bug
- Do not test every point release (16.1, 16.2, 17.0, etc.)

### For HabitStack specifically

Given Swift/SwiftUI + Supabase + RevenueCat:

| | Version |
|---|---|
| **Minimum target** | iOS 16 (covers ~95% of active users) |
| **Test on** | iOS 16 minimum, iOS 18 latest |
| **Skip** | 16.x, 17.x point releases unless a specific bug arises |

The App Store will catch obvious compatibility issues before publishing, and you can always bump the minimum target if needed.
