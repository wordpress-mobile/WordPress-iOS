import WordPressFlux
import Gridicons

open class QuickStartTourGuide: NSObject {
    @objc var navigationWatcher = QuickStartNavigationWatcher()
    private var currentSuggestion: QuickStartTour?
    private var currentTourState: TourState?
    static let notificationElementKey = "QuickStartElementKey"

    @objc static func find() -> QuickStartTourGuide? {
        guard let tabBarController = WPTabBarController.sharedInstance(),
            let tourGuide = tabBarController.tourGuide else {
            return nil
        }
        return tourGuide
    }
}

/// The API
internal extension QuickStartTourGuide {
    func setup(for blog: Blog) {
        let createTour = QuickStartCreateTour()
        completed(tourID: createTour.key, for: blog)
    }

    func suggest(_ tour: QuickStartTour, for blog: Blog) {
        // swallow suggestions if already suggesting or a tour is in progress
        guard currentSuggestion == nil, currentTourState == nil else {
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
                                    self?.start(tour: tour, for: blog)
                                } else {
                                    self?.skipped(tour, for: blog)
                                }
        }

        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    func start(tour: QuickStartTour, for blog: Blog) {
        endCurrentTour()
        dismissSuggestion()

        switch tour {
        case let tour as QuickStartFollowTour:
            tour.setupReaderTab()
            fallthrough
        default:
            currentTourState = TourState(tour: tour, blog: blog, step: 0)
            showCurrentStep()
        }
    }

    // we have this because poor stupid ObjC doesn't know what the heck an optional is
    @objc func currentElementInt() -> Int {
        return currentWaypoint()?.element.rawValue ?? NSNotFound
    }

    @objc func isCurrentElement(_ testElement: QuickStartTourElement) -> Bool {
        guard let currentElement = currentElement() else {
            return false
        }
        return testElement == currentElement
    }

    func shouldSpotlight(_ element: QuickStartTourElement) -> Bool {
        return currentElement() == element
    }

    @objc func visited(_ element: QuickStartTourElement) {
        guard element == currentElement(),
            let tourState = currentTourState else {
                return
        }

        dismissCurrentNotice()

        guard let nextStep = getNextStep() else {
            completed(tourID: tourState.tour.key, for: tourState.blog)
            currentTourState = nil

            // TODO: we could put a nice animation here
            return
        }
        currentTourState = nextStep

        showCurrentStep()
    }

    func endCurrentTour() {
        dismissCurrentNotice()
        currentTourState = nil
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

private extension QuickStartTourGuide {

    func completed(tourID: String, for blog: Blog) {
        blog.completeTour(tourID)

        NotificationCenter.default.post(name: .QuickStartTourElementChangedNotification, object: self, userInfo: [QuickStartTourGuide.notificationElementKey: QuickStartTourElement.tourCompleted])
    }

    func showCurrentStep() {
        guard let waypoint = currentWaypoint() else {
            return
        }

        showStepNotice(waypoint.description)

        NotificationCenter.default.post(name: .QuickStartTourElementChangedNotification, object: self, userInfo: [QuickStartTourGuide.notificationElementKey: waypoint.element])
    }

    func showStepNotice(_ description: NSAttributedString) {
        let noticeStyle = QuickStartNoticeStyle(attributedMessage: description)
        let notice = Notice(title: "Test Quick Start Notice", style: noticeStyle)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    func currentWaypoint() -> QuickStartTour.WayPoint? {
        guard let state = currentTourState,
            state.step < state.tour.waypoints.count else {
                return nil
        }
        return state.tour.waypoints[state.step]
    }

    func currentElement() -> QuickStartTourElement? {
        return currentWaypoint()?.element
    }

    func dismissSuggestion() {
        guard currentSuggestion != nil, let presenter = findNoticePresenter() else {
            return
        }

        currentSuggestion = nil
        presenter.dismissCurrentNotice()
    }

    func getNextStep() -> TourState? {
        guard let tourState = currentTourState,
            tourState.step + 1 < tourState.tour.waypoints.count else {
                return nil
        }

        return TourState(tour: tourState.tour, blog: tourState.blog, step: tourState.step + 1)
    }

    func skipped(_ tour: QuickStartTour, for blog: Blog) {
        blog.skipTour(tour.key)
    }

    func findNoticePresenter() -> NoticePresenter? {
        return (UIApplication.shared.delegate as? WordPressAppDelegate)?.noticePresenter
    }

    func dismissCurrentNotice() {
        guard let presenter = findNoticePresenter() else {
            return
        }

        presenter.dismissCurrentNotice()
        ActionDispatcher.dispatch(NoticeAction.empty)
        NotificationCenter.default.post(name: .QuickStartTourElementChangedNotification, object: self, userInfo: [QuickStartTourGuide.notificationElementKey: QuickStartTourElement.noSuchElement])
    }
}

internal extension NSNotification.Name {
    static let QuickStartTourElementChangedNotification = NSNotification.Name(rawValue: "QuickStartTourElementChangedNotification")
}

@objc
public enum QuickStartTourElement: Int {
    case noSuchElement
    case viewSite
    case checklist
    case themes
    case customize
    case newpost
    case sharing
    case connections
    case readerTab
    case readerBack
    case readerSearch
    case tourCompleted
}

private struct TourState {
    var tour: QuickStartTour
    var blog: Blog
    var step: Int
}
