import SwiftUI

/// A type that contains the configuration of the animated prompts in the Jetpack prologue screen
struct JetpackPromptsConfiguration {

    let size: CGSize
    let frameHeight: CGFloat
    let fontSize: CGFloat
    let totalHeight: CGFloat
    let hiddenRows: Int
    let maximumOffset: CGFloat

    let prompts: [JetpackPrompt]

    init(size: CGSize) {
        self.size = size

        var prompts = [JetpackPrompt]()

        let frameHeight = ceil(size.height / CGFloat(Constants.visibleRows)) + JetpackPromptView.totalVerticalPadding
        self.frameHeight = frameHeight

        let fontSize = floor((frameHeight - JetpackPromptView.totalVerticalPadding) * Constants.fontScaleFactor)
        self.fontSize = fontSize
        // sum of all the offsets + frame height of the last element = total height
        var cumulatedOffset: CGFloat = 0

        for row in Constants.prompts.enumerated() {
            let textHeight = row.element.height(withMaxWidth: size.width,
                                                font: UIFont.systemFont(ofSize: fontSize).bold())
            // double the frame height if the text spans over 2 rows
            let actualFrameHeight = textHeight > frameHeight ? 2 * frameHeight : frameHeight

            prompts.append(JetpackPrompt(index: row.offset,
                                         text: row.element,
                                         color: row.offset % 2 == 0 ? Constants.evenColor : Constants.oddColor,
                                         frameHeight: actualFrameHeight,
                                         initialOffset: cumulatedOffset))
            cumulatedOffset += actualFrameHeight
        }

        self.prompts = prompts
        self.totalHeight = cumulatedOffset
        self.hiddenRows = Int(totalHeight / frameHeight) - Constants.visibleRows
        self.maximumOffset = size.height + CGFloat(self.hiddenRows / 2) * frameHeight
    }
}

/// Text and constants
private extension JetpackPromptsConfiguration {

    enum Constants {
        // alternate colors in rows
        static let evenColor = Color(UIColor(light: .muriel(color: .jetpackGreen, .shade60),
                                             dark: .muriel(color: .jetpackGreen, .shade40)))
        static let oddColor = Color(UIColor(light: .muriel(color: .jetpackGreen, .shade20),
                                            dark: .muriel(color: .jetpackGreen, .shade5)))

        static let visibleRows = prompts.count / 2
        // Font size is calculated as a percentage of frame height
        static let fontScaleFactor: CGFloat = 0.8

        static let basePrompts = [
            NSLocalizedString("jetpack.prologue.prompt.watchStats",
                              value: "Watch your stats",
                              comment: "Watch your stats prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.checkNotifications",
                              value: "Check notifications",
                              comment: "Check notifications prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.buildSite",
                              value: "Build a site",
                              comment: "Build a site prompt for the jetpack prologue"),
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
                              comment: "Add an author prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.searchPosts",
                              value: "Serach for posts or sites",
                              comment: "Serach for posts or sites prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.writeBlog",
                              value: "Write a blog",
                              comment: "Write a blog prompt for the jetpack prologue"),
            NSLocalizedString("jetpack.prologue.prompt.readArticle",
                              value: "Read an article",
                              comment: "Read an article prompt for the jetpack prologue")
        ]

        // Duplicate the array to have enough cells for the rotation
        static let prompts = basePrompts + basePrompts
    }
}
