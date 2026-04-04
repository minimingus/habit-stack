# Better You — Launch Day Playbook

**Goal:** Go from "developer account activated" to "live on App Store + 1,000 downloads in 30 days" with $0 paid spend.

---

## Phase 0: Pre-Submission (Do NOW, before developer account)

### ASO — Keyword Field (100 chars)
Current keywords waste characters on "atomic" (can't outrank the book) and "mindfulness" (wrong intent).

**Optimized keywords:**
```
habit tracker,daily habits,habit building,routine tracker,streak,self improvement,AI coach,goals,better habits,consistency
```
(99 characters — every term has search volume and purchase intent)

### ASO — Title + Subtitle
- **Title:** Better You — AI Habit Coach *(includes "habit" + "AI" + "coach" — three high-intent keywords)*
- **Subtitle:** Build better habits with streaks & coaching *(adds "better habits", "streaks", "coaching")*

### Screenshot Checklist
Capture these 6 screens on iPhone 15 Pro Max simulator (1290x2796):
1. Identity selection — "Who do you want to become?"
2. Habit swipe cards — "Swipe to adopt habits"
3. Today view with streaks — "One tap. Every day."
4. Milestone celebration — "Celebrate consistency"
5. AI Coach conversation — "Your personal habit coach"
6. Analytics — "See your progress"

**Each screenshot needs a bold headline overlay.** Use Figma, Canva, or a screenshot framing tool. No raw simulator captures.

### App Review Prep
- [ ] Test account with pre-populated data (5 habits, some streaks, coach history)
- [ ] Ensure app works fully offline (except coach)
- [ ] Verify all paywall flows work in sandbox
- [ ] Privacy nutrition labels filled in App Store Connect
- [ ] Age rating questionnaire: 4+

---

## Phase 1: Submission Day (T+0)

**Target: submit within 4 hours of developer account activation.**

1. Enroll in Apple Developer Program ($99)
2. Create App Store Connect record
3. Configure RevenueCat products in App Store Connect:
   - Weekly: $2.99 with 3-day free trial (default plan — highest conversion)
   - Monthly: $7.99 with 7-day free trial
   - Annual: $59.99 with 7-day free trial (badge: "Best Value")
4. Upload build from Xcode (Archive → Distribute)
5. Fill metadata from `docs/appstore-metadata.md` (with updated keywords above)
6. Upload screenshots
7. Submit for review
8. Enable "Release manually" (so we can coordinate launch day)

**Expected review time:** 24-48 hours for new apps.

---

## Phase 2: Pre-Launch Content (Prepare while waiting for review)

### Ready-to-Post Content

Full copy-paste drafts for all channels are in `docs/launch-content-drafts.md`. Below is the scheduling strategy.

### Reddit (stagger across launch day)
- **r/getdisciplined** (1.5M) — 9 AM: identity-based story, no promotion
- **r/productivity** (2.5M) — 1 PM: developer story about context-aware AI coaching
- **r/habits** (200K) — 5 PM: Day 1 activation problem discussion

### Product Hunt
- **Schedule:** Tuesday 12:01 AM PT (highest traffic day)
- **Prep:** 5 upvotes from friends within first hour
- Full listing + maker comment in `docs/launch-content-drafts.md`

### Hacker News — Show HN
- **Schedule:** 10 AM PT on launch day
- Technical angle: SwiftUI + Claude API edge functions
- Full post in `docs/launch-content-drafts.md`

### Twitter/X — Build in Public (start 5-7 days before)
- Full 5-tweet launch thread in `docs/launch-content-drafts.md`

### IndieHackers
- Honest Day 1 post with real numbers
- Monthly MRR updates

---

## Phase 3: Launch Day (T+review)

1. Approve release in App Store Connect (manual release)
2. Post all prepared content within 2-hour window:
   - Product Hunt (12:01 AM PT)
   - Twitter launch thread (8 AM local)
   - Reddit posts (stagger: morning, afternoon, evening)
   - HN Show HN (10 AM PT)
   - IndieHackers (anytime)
3. Monitor reviews in App Store Connect — respond to every review within 24h
4. Watch PostHog funnel: onboarding_started → onboarding_completed → first_habit_completed

---

## Phase 4: Week 1 Metrics & Response

### Daily Dashboard Check (PostHog)
| Metric | Red Flag | Action |
|--------|----------|--------|
| Onboarding completion < 50% | Too many screens or confusion | Shorten flow |
| D1 retention < 40% | Not bridging to first habit | Check Day 1 notification |
| Paywall shown but 0 trial starts | Bad copy or timing | Update CTA copy |
| Coach usage < 10% of DAU | Not discoverable | Add coach prompt in Today view |
| Share card usage = 0 | Feature not visible | Add share CTA to milestones |

### Week 1 Priorities
1. Fix the biggest funnel drop-off (data-driven, not guessing)
2. Reply to all App Store reviews
3. Post MRR update on IndieHackers + Twitter
4. If reviews mention a specific pain point, ship a fix within 48h

---

## Revenue Targets

### With weekly plan (primary model)
| Timeframe | Downloads | Trial Starts | Paid | MRR |
|-----------|-----------|-------------|------|-----|
| Week 1 | 200 | 30 | 8 | $85 |
| Month 1 | 1,000 | 150 | 55 | $580 |
| Month 2 | 3,000 | 450 | 165 | $1,740 |
| Month 3 | 5,000 | 750 | 275 | $2,900 |

**Assumes 60% weekly ($2.99/wk), 30% monthly ($7.99), 10% annual ($59.99/yr). Blended ~$10.50/mo effective. Weekly plans convert 1.7-7.4x better than annual (RevenueCat 2025).**

### Without weekly plan (fallback)
| Timeframe | Downloads | Trial Starts | Paid | MRR |
|-----------|-----------|-------------|------|-----|
| Week 1 | 200 | 30 | 5 | $40 |
| Month 1 | 1,000 | 150 | 45 | $360 |
| Month 2 | 3,000 | 450 | 135 | $1,080 |
| Month 3 | 5,000 | 750 | 225 | $1,800 |

**Conservative at 15% trial start, 30% conversion, $7.99 monthly only.**

---

## Blockers

| Blocker | Owner | Status |
|---------|-------|--------|
| Apple Developer account enrollment | Board | **BLOCKING — #1 priority** |
| App Store screenshots (need Xcode simulator) | Board/Engineer | Ready to capture |
| RevenueCat product setup in App Store Connect | Board | Needs developer account |
