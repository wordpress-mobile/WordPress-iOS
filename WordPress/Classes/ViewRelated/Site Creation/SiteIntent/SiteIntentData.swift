import Foundation

struct SiteIntentData {
    private static let verticals: [SiteIntentVertical] = [
        .init("food", NSLocalizedString("Food", comment: "Food site intent topic"), "🍔", isDefault: true),
        .init("news", NSLocalizedString("News", comment: "News site intent topic"), "🗞️", isDefault: true),
        .init("lifestyle", NSLocalizedString("Lifestyle", comment: "Lifestyle site intent topic"), "☕", isDefault: true),
        .init("personal", NSLocalizedString("Personal", comment: "Personal site intent topic"), "✍️", isDefault: true),
        .init("photography", NSLocalizedString("Photography", comment: "Photography site intent topic"), "📷", isDefault: true),
        .init("travel", NSLocalizedString("Travel", comment: "Travel site intent topic"), "✈️", isDefault: true),
        .init("art", NSLocalizedString("Art", comment: "Art site intent topic"), "🎨"),
        .init("automotive", NSLocalizedString("Automotive", comment: "Automotive site intent topic"), "🚗"),
        .init("beauty", NSLocalizedString("Beauty", comment: "Beauty site intent topic"), "💅"),
        .init("books", NSLocalizedString("Books", comment: "Books site intent topic"), "📚"),
        .init("business", NSLocalizedString("Business", comment: "Business site intent topic"), "💼"),
        .init("community_nonprofit", NSLocalizedString("Community & Non-Profit", comment: "Community & Non-Profit site intent topic"), "🤝"),
        .init("education", NSLocalizedString("Education", comment: "Education site intent topic"), "🏫"),
        .init("diy", NSLocalizedString("DIY", comment: "DIY site intent topic"), "🔨"),
        .init("fashion", NSLocalizedString("Fashion", comment: "Fashion site intent topic"), "👠"),
        .init("finance", NSLocalizedString("Finance", comment: "Finance site intent topic"), "💰"),
        .init("film_television", NSLocalizedString("Film & Television", comment: "Film & Television site intent topic"), "🎥"),
        .init("fitness_exercise", NSLocalizedString("Fitness & Exercise", comment: "Fitness & Exercise site intent topic"), "💪"),
        .init("gaming", NSLocalizedString("Gaming", comment: "Gaming site intent topic"), "🎮"),
        .init("health", NSLocalizedString("Health", comment: "Health site intent topic"), "❤️"),
        .init("interior_design", NSLocalizedString("Interior Design", comment: "Interior Design site intent topic"), "🛋️"),
        .init("local_services", NSLocalizedString("Local Services", comment: "Local Services site intent topic"), "📍"),
        .init("music", NSLocalizedString("Music", comment: "Music site intent topic"), "🎵"),
        .init("parenting", NSLocalizedString("Parenting", comment: "Parenting site intent topic"), "👶"),
        .init("people", NSLocalizedString("People", comment: "People site intent topic"), "🧑‍🤝‍🧑"),
        .init("politics", NSLocalizedString("Politics", comment: "Politics site intent topic"), "🗳️"),
        .init("real_estate", NSLocalizedString("Real Estate", comment: "Real Estate site intent topic"), "🏠"),
        .init("sports", NSLocalizedString("Sports", comment: "Sports site intent topic"), "⚽"),
        .init("technology", NSLocalizedString("Technology", comment: "Technology site intent topic"), "💻"),
        .init("writing_poetry", NSLocalizedString("Writing & Poetry", comment: "Writing & Poetry site intent topic"), "📓")
    ]

    static let defaultVerticals: [SiteIntentVertical] = {
        verticals.filter { $0.isDefault }
    }()
}

fileprivate extension SiteIntentVertical {
    init(_ slug: String, _ localizedTitle: String, _ emoji: String, isDefault: Bool = false) {
        self.slug = slug
        self.localizedTitle = localizedTitle
        self.emoji = emoji
        self.isDefault = isDefault
    }
}
