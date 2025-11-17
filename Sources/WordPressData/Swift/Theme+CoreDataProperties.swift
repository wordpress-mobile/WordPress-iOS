import Foundation
import CoreData

public extension Theme {
    @NSManaged var author: String?
    @NSManaged var authorUrl: String?
    @NSManaged var demoUrl: String?
    @NSManaged var details: String?
    @NSManaged var launchDate: Date?
    @NSManaged var name: String?
    @NSManaged var order: NSNumber?
    @NSManaged var popularityRank: NSNumber?
    @NSManaged var premium: NSNumber?
    @NSManaged var previewUrl: String?
    @NSManaged var price: String?
    @NSManaged var purchased: NSNumber?
    @NSManaged var screenshotUrl: String?
    @NSManaged var stylesheet: String?
    @NSManaged var tags: [String]?
    @NSManaged var themeId: String?
    @NSManaged var themeUrl: String?
    @NSManaged var trendingRank: NSNumber?
    @NSManaged var version: String?
    /// Indicates if the theme is a custom (uploaded) theme, used only for Jetpack sites' themes
    /// custom = YES for uploaded themes, custom = NO for WordPress.com themes
    @NSManaged var custom: Bool

    @NSManaged var blog: Blog?
}
