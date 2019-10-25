import Foundation
import CocoaLumberjack
import WordPressShared

private enum PublishSettingsCell: CaseIterable {
    case dateTime
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
        return viewController
    }

    var noticeMessage: String?

    let title = NSLocalizedString("Publish", comment: "Title for the publish settings view")

    var immuTableRows: [ImmuTableRow.Type] {
        return [
            EditableTextRow.self
        ]
    }

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
                    action: presenter.present(dateTimeCalendar(model: viewModel))
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

    func dateTimeCalendar(model: PublishSettingsViewModel) -> (ImmuTableRow) -> UIViewController {
        return { [weak self] _ in

            //TODO: Show in popover

            let navigationController = LightNavigationController(rootViewController: SchedulingCalendarViewController())

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
