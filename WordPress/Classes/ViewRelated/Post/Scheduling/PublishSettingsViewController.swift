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
    }

    private(set) var state: State
    let timeZone: OffsetTimeZone?
    let title: String?

    private let post: AbstractPost

    init(post: AbstractPost) {
        if let dateCreated = post.dateCreated {
            state = post.hasFuturePublishDate() ? .scheduled(dateCreated) : .published(dateCreated)
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
            state = .scheduled(date)
            post.dateCreated = date
        } else {
            state = .immediately
        }

        /// Set the post's status to scheduled or published depending on our date value
        switch state {
        case .scheduled:
            post.status = .scheduled
        case .immediately:
            post.publishImmediately()
        case .published:
            /// Don't need to do anything for published states (based on previous logic in PostSettingsViewController)
            break
        }
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
                    detail: viewModel.date?.longStringWithTime() ?? NSLocalizedString("Immediately", comment: "Undated post time label"),
                    accessibilityIdentifier: "Date and Time Row",
                    action: presenter.present(dateTimeCalendarViewController(with: viewModel))
                )
            }
        }

        let footerText: String?

        if let date = viewModel.date {
            let publishedOnString = date.longStringWithTime()
            let offsetLabel = viewModel.timeZone?.label ?? NSLocalizedString("Unknown UTC Offset", comment: "Unknown UTC offset label")
            footerText = String.localizedStringWithFormat("Post will be published on %@ in your site timezone (%@)", publishedOnString, offsetLabel)
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
            schedulingCalendarViewController.coordinator = DateCoordinator(date: model.date) { [weak self] date in
                self?.viewModel.setDate(date)
                NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: ImmuTableViewController.modelChangedNotification), object: nil)
            }

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
