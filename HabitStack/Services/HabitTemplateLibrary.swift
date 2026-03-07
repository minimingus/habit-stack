import Foundation

enum HabitTemplateLibrary {

    // MARK: - Health

    static let drinkWater = HabitTemplate(
        name: "Drink Water", emoji: "💧", category: .health,
        identity: "stays hydrated",
        tinyVersion: "Take one sip",
        cue: "After I wake up", timeOfDay: .morning,
        reward: "Feel energized for the day"
    )
    static let walk = HabitTemplate(
        name: "Walk 10 Minutes", emoji: "🚶", category: .health,
        identity: "moves their body every day",
        tinyVersion: "Put on walking shoes",
        cue: "After lunch", timeOfDay: .afternoon,
        reward: "Enjoy fresh air and clear my head"
    )
    static let stretch = HabitTemplate(
        name: "Stretch 5 Minutes", emoji: "🧘", category: .health,
        identity: "takes care of their body",
        tinyVersion: "Do one stretch",
        cue: "After waking up", timeOfDay: .morning,
        reward: "Feel loose and ready to move"
    )
    static let exercise = HabitTemplate(
        name: "Exercise 30 Minutes", emoji: "💪", category: .health,
        identity: "exercises consistently",
        tinyVersion: "Put on workout clothes",
        cue: "After waking up", timeOfDay: .morning,
        reward: "Feel strong and accomplished"
    )
    static let sleep = HabitTemplate(
        name: "Sleep Before 11 PM", emoji: "💤", category: .health,
        identity: "prioritizes sleep",
        tinyVersion: "Turn off the lights",
        cue: "After brushing my teeth", timeOfDay: .evening,
        reward: "Wake up feeling rested"
    )

    // MARK: - Mind & Mental Health

    static let meditate = HabitTemplate(
        name: "Meditate 5 Minutes", emoji: "🧘", category: .mind,
        identity: "has a calm, focused mind",
        tinyVersion: "Take 3 deep breaths",
        cue: "After sitting at my desk", timeOfDay: .morning,
        reward: "Feel centered and present"
    )
    static let gratitude = HabitTemplate(
        name: "Practice Gratitude", emoji: "🙏", category: .mind,
        identity: "appreciates the good in life",
        tinyVersion: "Think of one good thing",
        cue: "Before sleep", timeOfDay: .evening,
        reward: "Fall asleep with a positive mindset"
    )
    static let journal = HabitTemplate(
        name: "Journal 5 Minutes", emoji: "✍️", category: .mind,
        identity: "reflects and grows through writing",
        tinyVersion: "Write one sentence",
        cue: "After brushing my teeth", timeOfDay: .evening,
        reward: "Feel clarity and release"
    )
    static let mindfulBreak = HabitTemplate(
        name: "Mindful Break", emoji: "🌊", category: .mind,
        identity: "manages stress well",
        tinyVersion: "Close eyes for 10 seconds",
        cue: "After finishing a task", timeOfDay: .allDay,
        reward: "Reset and refocus"
    )
    static let freshAir = HabitTemplate(
        name: "Step Outside for Fresh Air", emoji: "🌿", category: .mind,
        identity: "takes care of their mental health",
        tinyVersion: "Open a window",
        cue: "After lunch", timeOfDay: .afternoon,
        reward: "Feel refreshed and recharged"
    )

    // MARK: - Learning

    static let read = HabitTemplate(
        name: "Read 10 Minutes", emoji: "📚", category: .learning,
        identity: "reads every day",
        tinyVersion: "Read one page",
        cue: "After dinner", timeOfDay: .evening,
        reward: "Feel mentally stimulated"
    )
    static let newWord = HabitTemplate(
        name: "Learn a New Word", emoji: "🎓", category: .learning,
        identity: "expands their vocabulary daily",
        tinyVersion: "Read one word",
        cue: "After unlocking my phone", timeOfDay: .morning,
        reward: "Feel sharper and more articulate"
    )
    static let study = HabitTemplate(
        name: "Study 15 Minutes", emoji: "📖", category: .learning,
        identity: "invests in themselves through learning",
        tinyVersion: "Study for 2 minutes",
        cue: "After breakfast", timeOfDay: .morning,
        reward: "Feel progress toward my goals"
    )
    static let podcast = HabitTemplate(
        name: "Listen to a Podcast", emoji: "🎵", category: .learning,
        identity: "learns something new every day",
        tinyVersion: "Listen for 2 minutes",
        cue: "During my commute", timeOfDay: .morning,
        reward: "Arrive somewhere smarter"
    )
    static let practiceSkill = HabitTemplate(
        name: "Practice a Skill", emoji: "⭐", category: .learning,
        identity: "gets 1% better every day",
        tinyVersion: "Practice for 2 minutes",
        cue: "After work", timeOfDay: .evening,
        reward: "Feel the satisfaction of progress"
    )

    // MARK: - Productivity

    static let planDay = HabitTemplate(
        name: "Plan the Day", emoji: "📝", category: .productivity,
        identity: "is intentional with their time",
        tinyVersion: "Write one task",
        cue: "After opening my laptop", timeOfDay: .morning,
        reward: "Start the day with clarity and direction"
    )
    static let deepWork = HabitTemplate(
        name: "Deep Work Session", emoji: "💻", category: .productivity,
        identity: "does focused, meaningful work",
        tinyVersion: "Work for 2 minutes",
        cue: "After planning my day", timeOfDay: .morning,
        reward: "Feel the flow of focused work"
    )
    static let cleanWorkspace = HabitTemplate(
        name: "Clean Workspace", emoji: "🧹", category: .productivity,
        identity: "works in a clear, organized environment",
        tinyVersion: "Move one item",
        cue: "After work", timeOfDay: .evening,
        reward: "Feel ready for tomorrow"
    )
    static let reviewGoals = HabitTemplate(
        name: "Review Goals", emoji: "🎯", category: .productivity,
        identity: "stays aligned with their long-term vision",
        tinyVersion: "Read my goals list",
        cue: "During my morning routine", timeOfDay: .morning,
        reward: "Feel motivated and on track"
    )
    static let prepareTomorrow = HabitTemplate(
        name: "Prepare Tomorrow's Tasks", emoji: "⏰", category: .productivity,
        identity: "sets themselves up for success",
        tinyVersion: "Write one task for tomorrow",
        cue: "Before sleep", timeOfDay: .evening,
        reward: "Rest easy knowing tomorrow is ready"
    )

    // MARK: - Relationships

    static let messageAFriend = HabitTemplate(
        name: "Message a Friend", emoji: "❤️", category: .relationships,
        identity: "nurtures their relationships",
        tinyVersion: "Send a short text",
        cue: "After lunch", timeOfDay: .afternoon,
        reward: "Feel connected and cared for"
    )
    static let expressGratitude = HabitTemplate(
        name: "Express Gratitude to Someone", emoji: "🌞", category: .relationships,
        identity: "makes people feel appreciated",
        tinyVersion: "Say thank you",
        cue: "After an interaction", timeOfDay: .allDay,
        reward: "Strengthen a relationship"
    )
    static let callFamily = HabitTemplate(
        name: "Call a Family Member", emoji: "🏆", category: .relationships,
        identity: "stays close with family",
        tinyVersion: "Send a voice message",
        cue: "Sunday afternoon", timeOfDay: .afternoon,
        reward: "Feel loved and connected"
    )
    static let giveCompliment = HabitTemplate(
        name: "Give a Compliment", emoji: "🌅", category: .relationships,
        identity: "lifts others up",
        tinyVersion: "Say one kind word",
        cue: "When meeting someone", timeOfDay: .allDay,
        reward: "Brighten someone's day"
    )
    static let askAboutDay = HabitTemplate(
        name: "Ask Someone About Their Day", emoji: "🔥", category: .relationships,
        identity: "shows genuine interest in people",
        tinyVersion: "Ask one question",
        cue: "After dinner", timeOfDay: .evening,
        reward: "Deepen a connection"
    )

    // MARK: - All Templates

    static let all: [HabitTemplate] = [
        drinkWater, walk, stretch, exercise, sleep,
        meditate, gratitude, journal, mindfulBreak, freshAir,
        read, newWord, study, podcast, practiceSkill,
        planDay, deepWork, cleanWorkspace, reviewGoals, prepareTomorrow,
        messageAFriend, expressGratitude, callFamily, giveCompliment, askAboutDay,
    ]

    static func templates(for category: HabitCategory) -> [HabitTemplate] {
        all.filter { $0.category == category }
    }

    // MARK: - Starter Packs

    static let starterPacks: [StarterPack] = [
        StarterPack(
            name: "Better Mornings",
            icon: "sunrise.fill",
            templates: [drinkWater, stretch, planDay]
        ),
        StarterPack(
            name: "Calm Mind",
            icon: "brain.head.profile",
            templates: [meditate, gratitude, journal]
        ),
        StarterPack(
            name: "Learning",
            icon: "book.fill",
            templates: [read, newWord, podcast]
        ),
    ]
}
