import Foundation
import CocoaLumberjack
import WordPressShared

private enum PublishSettingsCell: CaseIterable {
    case dateTime

    var title: String {
        switch self {
        case .dateTime:
            return "Date and time"
        }
    }
}

struct PublishSettingsViewModel {
    enum State {
        case scheduled(Date)
        case published(Date)
        case immediately
    }

    private var state: State
    let timeZone: OffsetTimeZone?

    let title: String?

    private let post: AbstractPost

    init(post: AbstractPost) {
        if let dateCreated = post.dateCreated {
            if post.hasFuturePublishDate() {
                state = .scheduled(dateCreated)
            } else {
                state = .published(dateCreated)
            }
        } else {
            state = .immediately
        }

        self.post = post

        title = post.postTitle

        if let gmtOffset = post.blog.settings?.gmtOffset {
            timeZone = OffsetTimeZone(offset: gmtOffset.floatValue)
        } else {
            timeZone = nil
        }
    }

    fileprivate var cells: [PublishSettingsCell] {
        switch state {
        case .published, .immediately:
            return [PublishSettingsCell.dateTime]
        case .scheduled:
            return PublishSettingsCell.allCases
        }
    }

    var date: Date? {
        switch state {
        case .scheduled(let date), .published(let date):
            return date
        case .immediately:
            return nil
        }
    }

    mutating func setDate(_ date: Date?) {
        if let date = date {
            state = .scheduled(date)
        } else {
            state = .immediately
        }

        post.dateCreated = date
    }
}

@objc class PublishSettingsController: NSObject, SettingsController {

    @objc class func viewController(post: AbstractPost) -> ImmuTableViewController {
        let controller = PublishSettingsController(post: post)
        let viewController = ImmuTableViewController(controller: controller)
        return viewController
    }

    var noticeMessage: String?

    let title = NSLocalizedString("Publish", comment: "Title for the publish settings view")

    var immuTableRows: [ImmuTableRow.Type] {
        return [
            EditableTextRow.self
        ]
    }

    static var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    private var viewModel: PublishSettingsViewModel

    init(post: AbstractPost) {
        viewModel = PublishSettingsViewModel(post: post)

        let siteTimezoneOffset = viewModel.timeZone?.gmtOffset ?? 0
        let deviceTimezoneOffset = TimeZone.current.secondsFromGMT()/60/60
        if siteTimezoneOffset != Float(deviceTimezoneOffset) {
            noticeMessage = NSLocalizedString("Site time zone differs from device time zone", comment: "Notice that time zones are different when scheduling")
        }
    }

    func tableViewModelWithPresenter(_ presenter: ImmuTablePresenter) -> ImmuTable {
        return mapViewModel(viewModel, presenter: presenter)
    }

    func refreshModel() {
        // Don't need to refresh the model
    }

    func mapViewModel(_ viewModel: PublishSettingsViewModel, presenter: ImmuTablePresenter) -> ImmuTable {

        let rows: [ImmuTableRow] = viewModel.cells.map { cell in
            switch cell {
            case .dateTime:
                return EditableTextRow(
                    title: NSLocalizedString("Date and Time", comment: "Date and Time"),
                    value: viewModel.date?.shortStringWithTime() ?? NSLocalizedString("Immediately", comment: "Undated post time label"),
                    action: presenter.present(dateTimeCalendar(model: viewModel))
                )
            }
        }

        let footerText: String?

        if let date = viewModel.date {
            let publishedOnString = PublishSettingsController.dateFormatter.string(from: date)
            let offsetLabel = viewModel.timeZone?.label ?? "Unknown Offset"
            footerText = "Post will be published on \(publishedOnString) in your site time zone (\(offsetLabel))"
        } else {
            footerText = nil
        }


        return ImmuTable(sections: [
            ImmuTableSection(rows: rows, footerText: footerText)
        ])
    }

    func dateTimeCalendar(model: PublishSettingsViewModel) -> (ImmuTableRow) -> UIViewController {
        return { [weak self] _ in

            //TODO: Show in popover

            let navigationController = LightNavigationController(rootViewController: CalendarViewController())

            (navigationController.topViewController as? DateCoordinatorHandler)?.coordinator = DateCoordinator(date: model.date) { [weak self] date in
                self?.viewModel.setDate(date)
                NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: ImmuTableViewController.modelChangedNotification), object: nil)
            }

            navigationController.modalPresentationStyle = .custom
            navigationController.transitioningDelegate = self
            return navigationController
        }
    }
}

// The calendar sheet is shown towards the bottom half of the screen so a custom transitioning delegate is needed.
extension PublishSettingsController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return HalfScreenPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
