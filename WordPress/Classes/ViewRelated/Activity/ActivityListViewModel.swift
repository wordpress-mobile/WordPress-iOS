protocol ActivityRewindPresenter {
    func presentRewindFor(activity: Activity)
}

enum ActivityListViewModel {
    case loading
    case ready([Activity])
    case error(String)

    var noResultsViewModel: WPNoResultsView.Model? {
        switch self {
        case .loading:
            return WPNoResultsView.Model(
                title: NSLocalizedString("Loading Activities...",
                                         comment: "Text displayed while loading the activity feed for a site")
            )
        case .ready:
            return nil
        case .error:
            let appDelegate = WordPressAppDelegate.sharedInstance()
            if (appDelegate?.connectionAvailable)! {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("Oops", comment: ""),
                    message: NSLocalizedString("There was an error loading activities",
                                               comment: "Text displayed when there is a failure loading the activity feed"),
                    buttonTitle: NSLocalizedString("Contact support",
                                                   comment: "Button label for contacting support")
                )
            } else {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("No connection", comment: ""),
                    message: NSLocalizedString("An active internet connection is required to view activities", comment: "")
                )
            }
        }
    }

    func tableViewModel(presenter: ActivityRewindPresenter) -> ImmuTable {
        switch self {
        case .loading, .error:
            return .Empty
        case .ready(let activities):
            let rows = activities.map({ activity in
                return ActivityListRow(
                    activity: activity,
                    action: { (row) in
                        presenter.presentRewindFor(activity: activity)
                    }
                )
            })
            return ImmuTable(sections: [
                ImmuTableSection(rows: rows)
            ])
        }
    }
}
