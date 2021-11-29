import Foundation
import CocoaLumberjack
import WordPressShared
import WordPressFlux

enum PublishSettingsCell: CaseIterable {
    case dateTime
}

struct PublishSettingsViewModel {
    enum State {
        case scheduled(Date)
        case published(Date)
        case immediately

        init(post: AbstractPost) {
            if let dateCreated = post.dateCreated, post.shouldPublishImmediately() == false {
                self = post.hasFuturePublishDate() ? .scheduled(dateCreated) : .published(dateCreated)
            } else {
                self = .immediately
            }
        }
    }

    private(set) var state: State
    let timeZone: TimeZone
    let title: String?

    var detailString: String {
        if let date = date, !post.shouldPublishImmediately() {
            return dateTimeFormatter.string(from: date)
        } else {
            return NSLocalizedString("Immediately", comment: "Undated post time label")
        }
    }

    private let post: AbstractPost

    let dateFormatter: DateFormatter
    let dateTimeFormatter: DateFormatter

    init(post: AbstractPost, context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {
        if let dateCreated = post.dateCreated, post.shouldPublishImmediately() == false {
            state = post.hasFuturePublishDate() ? .scheduled(dateCreated) : .published(dateCreated)
        } else {
            state = .immediately
        }

        self.post = post

        title = post.postTitle
        timeZone = post.blog.timeZone

        dateFormatter = SiteDateFormatters.dateFormatter(for: timeZone, dateStyle: .long, timeStyle: .none)
        dateTimeFormatter = SiteDateFormatters.dateFormatter(for: timeZone, dateStyle: .medium, timeStyle: .short)
    }

    var cells: [PublishSettingsCell] {
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
            // If a date to schedule the post was given
            post.dateCreated = date
            if post.shouldPublishImmediately() {
                post.status = .publish
            } else {
                post.status = .scheduled
            }
        } else if post.originalIsDraft() {
            // If the original is a draft, keep the post as a draft
            post.status = .draft
            post.publishImmediately()
        } else if post.hasFuturePublishDate() {
            // If the original is a already scheduled post, change it to publish immediately
            // In this case the user had scheduled, but now wants to publish right away
            post.publishImmediately()
        }

        state = State(post: post)
    }
}

private struct DateAndTimeRow: ImmuTableRow {
   static let cell = ImmuTableCell.class(WPTableViewCellValue1.self)

   let title: String
   let detail: String
   let action: ImmuTableAction?
   let accessibilityIdentifer: String

   init(title: String, detail: String, accessibilityIdentifier: String, action: @escaping ImmuTableAction) {
       self.title = title
       self.detail = detail
       self.accessibilityIdentifer = accessibilityIdentifier
       self.action = action
   }

   func configureCell(_ cell: UITableViewCell) {
       cell.textLabel?.text = title
       cell.detailTextLabel?.text = detail
       cell.selectionStyle = .none
       cell.accessoryType = .none
       cell.accessibilityIdentifier = accessibilityIdentifer

       WPStyleGuide.configureTableViewCell(cell)
   }
}

@objc class PublishSettingsController: NSObject, SettingsController {
    var trackingKey: String {
        return "publish_settings"
    }

    @objc class func viewController(post: AbstractPost) -> ImmuTableViewController {
        let controller = PublishSettingsController(post: post)
        let viewController = ImmuTableViewController(controller: controller)
        controller.viewController = viewController
        return viewController
    }

    var noticeMessage: String?

    let title = NSLocalizedString("Publish", comment: "Title for the publish settings view")

    var immuTableRows: [ImmuTableRow.Type] {
        return [
            EditableTextRow.self
        ]
    }

    private weak var viewController: ImmuTableViewController?

    private var viewModel: PublishSettingsViewModel

    init(post: AbstractPost) {
        viewModel = PublishSettingsViewModel(post: post)
    }

    func tableViewModelWithPresenter(_ presenter: ImmuTablePresenter) -> ImmuTable {
        return mapViewModel(viewModel, presenter: presenter)
    }

    func refreshModel() {
        // Don't need to refresh the model here
        // This method is required by SettingsController but we don't need to respond to external updates on this screen
    }

    func mapViewModel(_ viewModel: PublishSettingsViewModel, presenter: ImmuTablePresenter) -> ImmuTable {

        let rows: [ImmuTableRow] = viewModel.cells.map { cell in
            switch cell {
            case .dateTime:
                return DateAndTimeRow(
                    title: NSLocalizedString("Date and Time", comment: "Date and Time"),
                    detail: viewModel.detailString,
                    accessibilityIdentifier: "Date and Time Row",
                    action: presenter.present(dateTimeCalendarViewController(with: viewModel))
                )
            }
        }

        let footerText: String?

        if let date = viewModel.date {
            let publishedOnString = viewModel.dateTimeFormatter.string(from: date)

            let offsetInHours = viewModel.timeZone.secondsFromGMT(for: date) / 60 / 60
            let offsetTimeZone = OffsetTimeZone(offset: Float(offsetInHours))
            let offsetLabel = offsetTimeZone.label

            switch viewModel.state {
            case .scheduled, .immediately:
                footerText = String.localizedStringWithFormat("Post will be published on %@ in your site timezone (%@)", publishedOnString, offsetLabel)
            case .published:
                footerText = String.localizedStringWithFormat("Post was published on %@ in your site timezone (%@)", publishedOnString, offsetLabel)
            }
        } else {
            footerText = nil
        }


        return ImmuTable(sections: [
            ImmuTableSection(rows: rows, footerText: footerText)
        ])
    }

    func dateTimeCalendarViewController(with model: PublishSettingsViewModel) -> (ImmuTableRow) -> UIViewController {
        return { [weak self] row in

            let schedulingCalendarViewController = SchedulingCalendarViewController()
            schedulingCalendarViewController.coordinator = DateCoordinator(
                date: model.date,
                timeZone: model.timeZone,
                dateFormatter: model.dateFormatter,
                dateTimeFormatter: model.dateTimeFormatter,
                updated: { [weak self] date in
                    WPAnalytics.track(.editorPostScheduledChanged, properties: ["via": "settings"])
                    self?.viewModel.setDate(date)
                    NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: ImmuTableViewController.modelChangedNotification), object: nil)
                }
            )

            return self?.calendarNavigationController(rootViewController: schedulingCalendarViewController) ?? UINavigationController()
        }
    }

    private func calendarNavigationController(rootViewController: UIViewController) -> UINavigationController {
        let navigationController = LightNavigationController(rootViewController: rootViewController)

        if viewController?.traitCollection.userInterfaceIdiom == .pad {
            navigationController.modalPresentationStyle = .popover
        } else {
            navigationController.modalPresentationStyle = .custom
            navigationController.transitioningDelegate = self
        }

        if let popoverController = navigationController.popoverPresentationController,
            let selectedIndexPath = viewController?.tableView.indexPathForSelectedRow {
            popoverController.sourceView = viewController?.tableView
            popoverController.sourceRect = viewController?.tableView.rectForRow(at: selectedIndexPath) ?? .zero
        }

        return navigationController
    }
}

// The calendar sheet is shown towards the bottom half of the screen so a custom transitioning delegate is needed.
extension PublishSettingsController: UIViewControllerTransitioningDelegate, UIAdaptivePresentationControllerDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = HalfScreenPresentationController(presentedViewController: presented, presenting: presenting)
        presentationController.delegate = self
        return presentationController
    }

    func adaptivePresentationStyle(for: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return traitCollection.verticalSizeClass == .compact ? .overFullScreen : .none
    }
}
