import WordPressFlux
import Gridicons

@objc
open class QuickStartTourGuide: NSObject, UINavigationControllerDelegate {
    private var currentSuggestion: QuickStartTour?

    static func find() -> QuickStartTourGuide? {
        guard let tabBarController = WPTabBarController.sharedInstance(),
            let tourGuide = tabBarController.tourGuide else {
            return nil
        }
        return tourGuide
    }

    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        switch viewController {
        case is QuickStartChecklistViewController:
            dismissTestQuickStartNotice()
        case is BlogListViewController:
            dismissSuggestion()
        default:
            break
        }
    }

    // MARK: Quick Start methods
    @objc
    func showTestQuickStartNotice() {
        let exampleMessage = "Tap %@ to see your checklist".highlighting(phrase: "Quick Start", icon: Gridicon.iconOfType(.listCheckmark))
        let noticeStyle = QuickStartNoticeStyle(attributedMessage: exampleMessage)
        let notice = Notice(title: "Test Quick Start Notice", style: noticeStyle)

        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    func suggest(_ tour: QuickStartTour, for blog: Blog) {
        // swallow subsequent suggestions
        guard currentSuggestion == nil else {
            return
        }
        currentSuggestion = tour

        let noticeStyle = QuickStartNoticeStyle(attributedMessage: nil)
        let notice = Notice(title: tour.title,
                            message: tour.description,
                            style: noticeStyle,
                            actionTitle: tour.suggestionYesText,
                            cancelTitle: tour.suggestionNoText) { [weak self] accepted in
                                self?.currentSuggestion = nil

                                if accepted {
                                    self?.showTestQuickStartNotice()
                                } else {
                                    self?.skipped(tour, for: blog)
                                }
        }

        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    private func dismissSuggestion() {
        guard currentSuggestion != nil, let presenter = findNoticePresenter() else {
            return
        }

        currentSuggestion = nil
        presenter.dismissCurrentNotice()
    }

    public func setup(for blog: Blog) {
        let createTour = QuickStartCreateTour()
        completed(tourID: createTour.key, for: blog)
    }

    private func skipped(_ tour: QuickStartTour, for blog: Blog) {
        blog.skipTour(tour.key)
    }

    public func completed(tourID: String, for blog: Blog) {
        blog.completeTour(tourID)
    }

    private func findNoticePresenter() -> NoticePresenter? {
        return (UIApplication.shared.delegate as? WordPressAppDelegate)?.noticePresenter
    }

    func dismissTestQuickStartNotice() {
        guard let presenter = findNoticePresenter() else {
            return
        }

        presenter.dismissCurrentNotice()
    }

    static let checklistTours: [QuickStartTour] = [
        QuickStartCreateTour(),
        QuickStartViewTour(),
        QuickStartThemeTour(),
        QuickStartCustomizeTour(),
        QuickStartShareTour(),
        QuickStartPublishTour(),
        QuickStartFollowTour()
    ]
}

private extension String {
    func highlighting(phrase: String, icon: UIImage) -> NSAttributedString {
        let normalParts = components(separatedBy: "%@")
        guard normalParts.count > 0 else {
            // if the provided base doesn't contain %@ then we don't know where to place the highlight
            return NSAttributedString(string: self)
        }
        let resultString = NSMutableAttributedString(string: normalParts[0])

        let font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)

        let iconAttachment = NSTextAttachment()
        iconAttachment.image = icon.imageWithTintColor(Constants.highlightColor)
        iconAttachment.bounds = CGRect(x: 0.0, y: font.descender + Constants.iconOffset, width: Constants.iconSize, height: Constants.iconSize)
        let iconStr = NSAttributedString(attachment: iconAttachment)

        let highlightStr = NSAttributedString(string: phrase, attributes: [.foregroundColor: Constants.highlightColor, .font: Constants.highlightFont])

        switch UIView.userInterfaceLayoutDirection(for: .unspecified) {
        case .rightToLeft:
            resultString.append(highlightStr)
            resultString.append(NSAttributedString(string: " "))
            resultString.append(iconStr)
        default:
            resultString.append(iconStr)
            resultString.append(NSAttributedString(string: " "))
            resultString.append(highlightStr)
        }

        if normalParts.count > 1 {
            resultString.append(NSAttributedString(string: normalParts[1]))
        }

        return resultString
    }

    private enum Constants {
        static let iconOffset: CGFloat = 1.0
        static let iconSize: CGFloat = 16.0
        static let highlightColor = WPStyleGuide.lightBlue()
        static var highlightFont: UIFont {
            get {
                return WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
            }
        }
    }
}
