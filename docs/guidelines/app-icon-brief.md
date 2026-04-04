# Better You — App Icon Design Brief

## Requirements
- **Format:** 1024x1024 PNG, no alpha channel, no rounded corners (iOS applies them)
- **Destination:** `HabitStack/Assets.xcassets/AppIcon.appiconset/`
- Must be legible at 29x29pt (smallest iOS size)

## Brand Direction

**App name:** Better You
**Category:** Health & Fitness
**Core concept:** Identity-based habit building. Consistency over intensity. Calm growth, not hustle.

**Brand colors in the app:**
- Primary: Teal (`Color("Teal")`)
- Background: Off-white/cream
- Accent: Warm stone tones

## Icon Options (pick one direction)

### Option A: Abstract Growth
A simple upward-curving path or sprout on a teal background. Conveys growth, progress, consistency. Similar energy to Headspace or Calm — clean, minimal, premium.

### Option B: Identity Symbol
A subtle silhouette or person outline with an upward arrow or glow. Conveys "becoming a better version of yourself." Think: person + transformation.

### Option C: Streak Visualization
A series of small dots or checkmarks forming an ascending pattern. Conveys daily consistency and compound progress. Clean, geometric.

## What to Avoid
- Checkmarks alone (too generic, looks like a to-do app)
- Flames or fire (overused for streaks, not our tone)
- Overly complex illustrations (won't read at small sizes)
- Bright/neon colors (our brand is calm and grounded)
- Text in the icon (doesn't scale)

## Competitive Context
Most habit tracker icons use checkmarks (Productive, Habitify) or abstract shapes (Streaks). Standing out means going calmer and more identity-focused — closer to wellness (Headspace, Calm) than productivity (Things, Todoist).

## Deliverable
Single 1024x1024 PNG file. Name it `AppIcon.png` and place in:
```
HabitStack/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

Update `Contents.json` in the same directory to reference the filename:
```json
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```
