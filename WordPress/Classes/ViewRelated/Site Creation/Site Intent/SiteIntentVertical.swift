import Foundation

struct SiteIntentVertical: Equatable {
    let slug: String
    let localizedTitle: String
    let emoji: String
    let isDefault: Bool
    let isCustom: Bool

    init(slug: String, localizedTitle: String, emoji: String, isDefault: Bool = false, isCustom: Bool = false) {
        self.slug = slug
        self.localizedTitle = localizedTitle
        self.emoji = emoji
        self.isDefault = isDefault
        self.isCustom = isCustom
    }
}
