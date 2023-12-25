import SwiftUI

/// Text and constants for animated prompts in the Jetpack prologue screen
struct JetpackPromptsConfiguration {

    enum Constants {
        // alternate colors in rows
        static let evenColor = UIColor(hexString: "3858E3")
        static let oddColor = UIColor.muriel(color: .jetpackGreen, .shade40)

        static let basePrompts = [
            NSLocalizedString("jetpack.prologue.prompt.updatePlugin",
                              value: "Update a plugin",
                              comment: "Update a plugin prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.buildSite",
                              value: "Build a site",
                              comment: "Build a site prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.writeBlog",
                              value: "Write a blog",
                              comment: "Write a blog prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.watchStats",
                              value: "Watch your stats",
                              comment: "Watch your stats prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.checkNotifications",
                              value: "Check notifications",
                              comment: "Check notifications prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.respondComments",
                              value: "Respond to comments",
                              comment: "Respond to comments prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.restoreBackup",
                              value: "Restore a backup",
                              comment: "Restore a backup prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.searchPlugins",
                              value: "Search for plugins",
                              comment: "Search for plugins prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.fbShare",
                              value: "Share on Facebook",
                              comment: "Share on Facebook prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.fixSecurity",
                              value: "Fix a security issue",
                              comment: "Fix a security issue prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.postPhoto",
                              value: "Post a photo",
                              comment: "Post a photo prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.addAuthor",
                              value: "Add an author",
                              comment: "Add an author prompt for the jetpack prologue")
        ]
    }
}
