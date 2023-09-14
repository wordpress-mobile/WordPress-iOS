import WordPressFlux

struct TimeZoneSelectorViewModel: Observable {
    enum State {
        case loading
        case ready([TimeZoneGroup])
        case error(Error)

        static func with(storeState: TimeZoneStoreState) -> State {
            switch storeState {
            case .empty, .loading:
                return .loading
            case .loaded(let groups):
                return .ready(groups)
            case .error(let error):
                return .error(error)
            }
        }
    }

    var state: State = .loading {
        didSet {
            emitChange()
        }
    }

    var selectedValue: String? {
        didSet {
            emitChange()
        }
    }

    var filter: String? {
        didSet {
            emitChange()
        }
    }

    let changeDispatcher = Dispatcher<Void>()

    var groups: [TimeZoneGroup] {
        guard case .ready(let groups) = state else {
            return []
        }
        return groups
    }

    var filteredGroups: [TimeZoneGroup] {
        guard let filter = filter else {
            return groups
        }

        return groups.compactMap({ (group) in
            if group.name.localizedCaseInsensitiveContains(filter) {
                return group
            } else {
                let timezones = group.timezones.filter({ $0.label.localizedCaseInsensitiveContains(filter) })
                if timezones.isEmpty {
                    return nil
                } else {
                    return TimeZoneGroup(name: group.name, timezones: timezones)
                }
            }
        })
    }

    private let timeZoneFormatter = TimeZoneFormatter(currentDate: Date())

    func getTimeZoneForIdentifier(_ timeZoneIdentifier: String) -> WPTimeZone? {
        return groups
                .flatMap({ $0.timezones })
                .filter({ $0.value.lowercased() == timeZoneIdentifier.lowercased() })
                .first
    }

    func tableViewModel(selectionHandler: @escaping (WPTimeZone) -> Void) -> ImmuTable {
        return ImmuTable(
                sections: filteredGroups.map({ (group) -> ImmuTableSection in
                    return ImmuTableSection(
                            headerText: group.name,
                            rows: group.timezones.map({ (timezone) -> ImmuTableRow in
                                return TimeZoneRow(title: timezone.label,
                                                   leftSubtitle: timeZoneFormatter.getZoneOffset(timezone),
                                                   rightSubtitle: timeZoneFormatter.getTimeAtZone(timezone),
                                                   action: { _ in
                                    selectionHandler(timezone)
                                })
                            }))
                })
        )
    }

    var noResultsViewModel: NoResultsViewController.Model? {
        switch state {
        case .loading:
            return NoResultsViewController.Model(title: LocalizedText.loadingTitle, accessoryView: NoResultsViewController.loadingAccessoryView())
        case .ready:
            return nil
        case .error:
            let appDelegate = WordPressAppDelegate.shared

            guard let connectionAvailable = appDelegate?.connectionAvailable, connectionAvailable == true else {
                return NoResultsViewController.Model(title: LocalizedText.noConnectionTitle,
                                                     subtitle: LocalizedText.noConnectionSubtitle)
            }

            return NoResultsViewController.Model(title: LocalizedText.errorTitle,
                    subtitle: LocalizedText.errorSubtitle,
                    buttonText: LocalizedText.buttonText)
        }
    }

    struct LocalizedText {
        static let loadingTitle = NSLocalizedString("Loading...", comment: "Text displayed while loading time zones")
        static let errorTitle = NSLocalizedString("Oops", comment: "Title for the view when there's an error loading time zones")
        static let errorSubtitle = NSLocalizedString("There was an error loading time zones", comment: "Error message when time zones can't be loaded")
        static let buttonText = NSLocalizedString("Contact support", comment: "Title of a button. A call to action to contact support for assistance.")
        static let noConnectionTitle = NSLocalizedString("No connection", comment: "Title for the error view when there's no connection")
        static let noConnectionSubtitle = NSLocalizedString("An active internet connection is required", comment: "Error message when loading failed because there's no connection")
    }

}
