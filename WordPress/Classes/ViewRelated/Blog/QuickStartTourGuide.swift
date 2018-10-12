import WordPressFlux
import Gridicons

@objc
open class QuickStartTourGuide: NSObject, UINavigationControllerDelegate {
    @objc var navigationWatcher = QuickStartNavigationWatcher()
    private var currentSuggestion: QuickStartTour?
    private var currentTourState: TourState?

    @objc static func find() -> QuickStartTourGuide? {
        guard let tabBarController = WPTabBarController.sharedInstance(),
            let tourGuide = tabBarController.tourGuide else {
            return nil
        }
        return tourGuide
    }

    // MARK: Quick Start methods
    @objc
    func showTestQuickStartNotice() {
        let exampleMessage = QuickStartChecklistTour().waypoints[0].description
        let noticeStyle = QuickStartNoticeStyle(attributedMessage: exampleMessage)
        let notice = Notice(title: "Test Quick Start Notice", style: noticeStyle)

        ActionDispatcher.dispatch(NoticeAction.post(notice))
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
        dismissSuggestion()

        switch tour {
        case is QuickStartViewTour, is QuickStartThemeTour, is QuickStartCustomizeTour:
            currentTourState = TourState(tour: tour, blog: blog, step: 0)
            showCurrentStep()
        default:
            // this is the last use of showTestQuickStartNotice(), when it's gone delete that method
            showTestQuickStartNotice()
        }
    }

    func endCurrentTour() {
        dismissCurrentNotice()
        currentTourState = nil
    }

    func showStepNotice(_ description: NSAttributedString) {
        let noticeStyle = QuickStartNoticeStyle(attributedMessage: description)
        let notice = Notice(title: "Test Quick Start Notice", style: noticeStyle)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    public func shouldSpotlight(_ element: QuickStartTourElement) -> Bool {
        return currentElement() == element
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

    private func getNextStep() -> TourState? {
        guard let tourState = currentTourState,
            tourState.step + 1 < tourState.tour.waypoints.count else {
                return nil
        }

        return TourState(tour: tourState.tour, blog: tourState.blog, step: tourState.step + 1)
    }

    public func showCurrentStep() {
        guard let waypoint = currentWaypoint() else {
            return
        }

        showStepNotice(waypoint.description)
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

    func dismissCurrentNotice() {
        guard let presenter = findNoticePresenter() else {
            return
        }

        presenter.dismissCurrentNotice()
    }

    @objc
    public func visited(_ element: QuickStartTourElement) {
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

@objc
public enum QuickStartTourElement: Int {
    case noSuchElement
    case viewSite
    case checklist
    case themes
    case customize
}

private struct TourState {
    var tour: QuickStartTour
    var blog: Blog
    var step: Int
}
