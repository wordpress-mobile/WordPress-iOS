
/// Configures a view controller to show the intro screen for the stories feature.
struct StoriesIntro {

    /// Called when the user taps the continue button and the stories editor should be shown.
    let continueTapped: () -> Void

    /// Called when the user taps one of the demo stories to open the URL.
    let openURL: (URL) -> Void

    /// Creates a configured view controller.
    /// - Returns: A view controller to present which shows the stories intro screen.
    func makeController() -> UIViewController {
        let titles = WhatIsNewViewTitles(header: NSLocalizedString("Introducing Story Posts", comment: "Stories intro header title"),
                                       version: "",
                                       continueButtonTitle: NSLocalizedString("Create Story Post", comment: "Stories intro continue button title"))

        let view = WhatIsNewView(viewTitles: titles, dataSource: dataSource, showsBackButton: true)

        let viewController = WhatIsNewViewController(whatIsNewViewFactory: {
            return view
        })

        view.continueAction = {
            trackContinue()
            continueTapped()
        }

        view.dismissAction = { [weak viewController] in
            trackDismissed()
            viewController?.dismiss(animated: true, completion: nil)
        }

        return viewController
    }

    /// To be called when the view controller from `makeController` is shown.
    func trackShown() {
        WPAnalytics.track(.storyIntroShown)
    }

    private func trackDismissed() {
        WPAnalytics.track(.storyIntroDismissed)
    }

    private func trackContinue() {
        WPAnalytics.track(.storyIntroCreateStoryButtonTapped)
    }

    // MARK: - Data Source]

    private var dataSource: StoriesIntroDataSource {

        let storyQueryItems = [URLQueryItem.WPStory.fullscreen, URLQueryItem.WPStory.playOnLoad]

        let gridItems = [
            GridCell.Item(image: UIImage(named: "democover01")!,
                          description: NSLocalizedString("How to create a story post", comment: "How to create story description"),
                          action: {
                            if let url = URL(string: "https://wpstories.wordpress.com/2020/10/12/patagonia-2/")?.add(storyQueryItems) {
                                openURL(url)
                            }
            }),
            GridCell.Item(image: UIImage(named: "democover02")!,
                          description: NSLocalizedString("Example story title", comment: "Example story title description"),
                          action: {
                            if let url = URL(string: "https://wpstories.wordpress.com/2020/10/12/hiking-in-the-southwest/")?.add(storyQueryItems) {
                                openURL(url)
                            }
            })]

        let dataSource = StoriesIntroDataSource(items: [
            StoriesIntroDataSource.Grid(title: NSLocalizedString("You've got early access to story posts and we'd love for you to give it a try.", comment: "Story Intro welcome title"), items: gridItems),
            StoriesIntroDataSource.AnnouncementItem(title: NSLocalizedString("Now stories are for everyone", comment: "First story intro item title"), description: NSLocalizedString("Combine photos, videos, and text to create engaging and tappable story posts that your visitors will love.", comment: "First story intro item description")),
            StoriesIntroDataSource.AnnouncementItem(title: NSLocalizedString("Story posts don't disappear", comment: "Second story intro item description"), description: NSLocalizedString("They're published as a new blog post on your site so your audience never misses out on a thing.", comment: "Second story intro item description"))
        ])

        return dataSource
    }
}

fileprivate extension URLQueryItem {
    /// Query Parameters to be used for the WP Stories feature.
    /// These can be used appended to the URL for any WordPress blog post
    enum WPStory {

        /// Opens the story in fullscreen.
        static let fullscreen = URLQueryItem(name: "wp-story-load-in-fullscreen", value: "true")

        /// Begins playing the story immediately.
        static let playOnLoad = URLQueryItem(name: "wp-story-play-on-load", value: "true")
    }
}

fileprivate extension URL {
    /// Appends query items to the URL.
    /// - Parameter newQueryItems: The new query items to add to the URL. These will **not** overwrite any existing items but are appended to the existing list.
    /// - Returns: The URL with added query items.
    func add(_ newQueryItems: [URLQueryItem]) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        queryItems.append(contentsOf: newQueryItems)
        components?.queryItems = queryItems
        return components?.url ?? self
    }
}

// MARK: - Data Source Types

/// A type which can register and vend cells for a table view.
protocol CellItem {
    func registerCells(in tableView: UITableView)
    func cell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell
}

fileprivate class StoriesIntroDataSource: NSObject, AnnouncementsDataSource {

    struct AnnouncementItem: CellItem {

        let title: String
        let description: String

        typealias Cell = AnnouncementCell
        private let reuseIdentifier = "announcementCell"

        func registerCells(in tableView: UITableView) {
            tableView.register(Cell.self, forCellReuseIdentifier: reuseIdentifier)
        }

        func cell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
            (cell as? Cell)?.configure(title: title, description: description, image: nil)
            return cell
        }
    }

    struct Grid: CellItem {

        let title: String
        let items: [GridCell.Item]

        typealias Cell = GridCell
        private let reuseIdentifier = "gridCell"

        func registerCells(in tableView: UITableView) {
            tableView.register(Cell.self, forCellReuseIdentifier: reuseIdentifier)
        }

        func cell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
            (cell as? Cell)?.configure(title: title, items: items)
            return cell
        }
    }

    let items: [CellItem]

    init(items: [CellItem]) {
        self.items = items
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        return item.cell(for: indexPath, in: tableView)
    }

    func registerCells(for tableView: UITableView) {
        items.forEach { item in
            item.registerCells(in: tableView)
        }
    }

    var dataDidChange: (() -> Void)?
}
