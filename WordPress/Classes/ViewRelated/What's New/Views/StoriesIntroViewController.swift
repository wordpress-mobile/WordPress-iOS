
class StoriesIntroViewController: WhatIsNewViewController {

    enum Constants {
        static let headerTitle = NSLocalizedString("Introducing Story Posts", comment: "Stories intro header title")
        static let continueButtonTitle = NSLocalizedString("Create Story Post", comment: "Stories intro continue button title")

        static let exampleHeaderTitle = NSLocalizedString("A new way to create and publish engaging content on your site.", comment: "Story Intro welcome title")

        static let example1Image = UIImage(named: "stories_intro_cover_1")
        static let example1Description = NSLocalizedString("How to create a story post", comment: "How to create story description")
        static let example1URL = URL(string: "https://wpstories.wordpress.com/2021/02/09/story-demo-03/")

        static let example2Image = UIImage(named: "stories_intro_cover_2")
        static let example2Description = NSLocalizedString("Example story title", comment: "Example story title description")
        static let example2URL = URL(string: "https://wpstories.wordpress.com/2020/12/02/story-demo-02/")

        static let announcement1Title = NSLocalizedString("Now stories are for everyone", comment: "First story intro item title")
        static let announcement1Description = NSLocalizedString("Combine photos, videos, and text to create engaging and tappable story posts that your visitors will love.", comment: "First story intro item description")

        static let announcement2Title = NSLocalizedString("Story posts don't disappear", comment: "Second story intro item description")
        static let announcement2Description = NSLocalizedString("They're published as a new blog post on your site so your audience never misses out on a thing.", comment: "Second story intro item description")
    }

    init(continueTapped: @escaping () -> Void, openURL: @escaping (URL) -> Void) {
        let titles = WhatIsNewViewTitles(header: Constants.headerTitle,
                                       version: "",
                                       continueButtonTitle: Constants.continueButtonTitle)

        let storyQueryItems = [URLQueryItem.WPStory.fullscreen, URLQueryItem.WPStory.playOnLoad]

        let gridItems = [
            GridCell.Item(image: Constants.example1Image,
                          description: Constants.example1Description,
                          action: {
                            if let url = Constants.example1URL?.appendingQueryItems(storyQueryItems) {
                                openURL(url)
                            }
            }),
            GridCell.Item(image: Constants.example2Image,
                          description: Constants.example2Description,
                          action: {
                            if let url = Constants.example2URL?.appendingQueryItems(storyQueryItems) {
                                openURL(url)
                            }
            })]

        let dataSource = StoriesIntroDataSource(items: [
            StoriesIntroDataSource.Grid(title: Constants.exampleHeaderTitle, items: gridItems),
            StoriesIntroDataSource.AnnouncementItem(title: Constants.announcement1Title, description: Constants.announcement1Description),
            StoriesIntroDataSource.AnnouncementItem(title: Constants.announcement2Title, description: Constants.announcement2Description)
        ])

        super.init(whatIsNewViewFactory: {
            return WhatIsNewView(viewTitles: titles, dataSource: dataSource, showsBackButton: true)
        }, onContinue: {
            StoriesIntroViewController.trackContinue()
            continueTapped()
        }, onDismiss: {
            StoriesIntroViewController.trackDismiss()
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Whether the user has already seen and acknowledged the Stories Intro screen.
    var acknowledged: Bool {
        return UserDefaults.standard.storiesIntroWasAcknowledged
    }

    // MARK: - Analytics

    /// To be called when the view controller from `makeController` is shown.
    static func trackShown() {
        WPAnalytics.track(.storyIntroShown)
    }

    static func trackContinue() {
        WPAnalytics.track(.storyIntroCreateStoryButtonTapped)
    }

    static func trackDismiss() {
        WPAnalytics.track(.storyIntroDismissed)
    }
}

// MARK: - Helpers

extension UserDefaults {
    private enum Keys: String {
        case storiesIntroWasAcknowledged = "storiesIntroWasAcknowledged"
    }

    var storiesIntroWasAcknowledged: Bool {
        get {
            return bool(forKey: Keys.storiesIntroWasAcknowledged.rawValue)
        }
        set {
            set(newValue, forKey: Keys.storiesIntroWasAcknowledged.rawValue)
        }
    }
}
