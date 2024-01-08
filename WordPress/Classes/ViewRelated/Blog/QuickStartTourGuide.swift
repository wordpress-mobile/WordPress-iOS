import WordPressFlux
import Gridicons
import Foundation
import UIKit
import WordPressShared

@objc enum QuickStartTourEntryPoint: Int {
    case unknown
    case blogDetails
    case blogDashboard
}

open class QuickStartTourGuide: NSObject {
    var navigationSettings = QuickStartNavigationSettings()
    private var currentSuggestion: QuickStartTour?
    private var currentTourState: TourState?
    private var suggestionWorkItem: DispatchWorkItem?
    private weak var recentlyTouredBlog: Blog?
    private let noticeTag: Notice.Tag = "QuickStartTour"
    private let noticeCompleteTag: Notice.Tag = "QuickStartTaskComplete"
    static let notificationElementKey = "QuickStartElementKey"
    static let notificationDescriptionKey = "QuickStartDescriptionKey"

    /// A flag indicating if the user is currently going through a tour or not.
    private(set) var tourInProgress = false

    /// A flag indidcating whether we should show the congrats notice or not.
    private var shouldShowCongratsNotice = false

    /// Represents the current entry point.
    @objc var currentEntryPoint: QuickStartTourEntryPoint = .unknown

    /// Represents the entry point where the current tour in progress was triggered from.
    @objc var entryPointForCurrentTour: QuickStartTourEntryPoint = .unknown

    /// A flag indicating if the current tour can only be shown from blog details or not.
    @objc var currentTourMustBeShownFromBlogDetails: Bool {
        guard let tourState = currentTourState else {
            return false
        }

        return tourState.tour.mustBeShownInBlogDetails
    }

    @objc static let shared = QuickStartTourGuide()

    private override init() {}

    func setup(for blog: Blog, type: QuickStartType, withCompletedSteps steps: [QuickStartTour] = []) {
        guard JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() else {
            return
        }

        if type == .newSite {
            let createTour = QuickStartCreateTour()
            completed(tour: createTour, for: blog)
        }

        steps.forEach { (tour) in
            completed(tour: tour, for: blog)
        }
        tourInProgress = false
        blog.quickStartType = type

        NotificationCenter.default.post(name: .QuickStartTourElementChangedNotification, object: self)
        WPAnalytics.trackQuickStartEvent(.quickStartStarted, blog: blog)
        NotificationCenter.default.post(name: .QuickStartTourElementChangedNotification,
                                        object: self,
                                        userInfo: [QuickStartTourGuide.notificationElementKey: QuickStartTourElement.setupQuickStart])
    }

    func setupWithDelay(for blog: Blog, type: QuickStartType, withCompletedSteps steps: [QuickStartTour] = []) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.quickStartDelay) {
            self.setup(for: blog, type: type, withCompletedSteps: steps)
        }
    }

    @objc func remove(from blog: Blog) {
        blog.removeAllTours()
        blog.quickStartType = .undefined
        endCurrentTour()
        NotificationCenter.default.post(name: .QuickStartTourElementChangedNotification, object: self)
        refreshQuickStart()
    }

    @objc static func quickStartEnabled(for blog: Blog) -> Bool {
        return JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() && QuickStartFactory.collections(for: blog).isEmpty == false
    }

    /// Provides a tour to suggest to the user
    ///
    /// - Parameter blog: The Blog for which to suggest a tour.
    /// - Returns: A QuickStartTour to suggest. `nil` if there are no appropriate tours.
    func tourToSuggest(for blog: Blog) -> QuickStartTour? {
        let completedTours: [QuickStartTourState] = blog.completedQuickStartTours ?? []
        let skippedTours: [QuickStartTourState] = blog.skippedQuickStartTours ?? []
        let unavailableTours = Array(Set(completedTours + skippedTours))
        let allTours = QuickStartFactory.allTours(for: blog)

        guard QuickStartTourGuide.quickStartEnabled(for: blog),
            recentlyTouredBlog == blog else {
                return nil
        }

        let unavailableIDs = unavailableTours.map { $0.tourID }
        let remainingTours = allTours.filter { !unavailableIDs.contains($0.key) }

        return remainingTours.first
    }

    func suggest(_ tour: QuickStartTour, for blog: Blog) {
        // swallow suggestions if already suggesting or a tour is in progress
        guard currentSuggestion == nil, currentTourState == nil else {
            return
        }
        currentSuggestion = tour

        let cancelTimer = { [weak self] (skipped: Bool) in
            self?.suggestionWorkItem?.cancel()
            self?.suggestionWorkItem = nil

            if skipped {
                self?.skipped(tour, for: blog)
            }
        }

        let newWorkItem = DispatchWorkItem { [weak self] in
            self?.dismissSuggestion()
            cancelTimer(true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.suggestionTimeout, execute: newWorkItem)
        suggestionWorkItem = newWorkItem

        let noticeStyle = QuickStartNoticeStyle(attributedMessage: nil)
        let notice = Notice(title: tour.title,
                            message: tour.description,
                            style: noticeStyle,
                            actionTitle: tour.suggestionYesText,
                            cancelTitle: tour.suggestionNoText,
                            tag: noticeTag) { [weak self] accepted in
                                self?.currentSuggestion = nil

                                if accepted {
                                    self?.prepare(tour: tour, for: blog)
                                    self?.begin()
                                    cancelTimer(false)
                                    WPAnalytics.trackQuickStartStat(.quickStartSuggestionButtonTapped,
                                                                    properties: ["type": "positive"],
                                                                    blog: blog)
                                } else {
                                    self?.skipped(tour, for: blog)
                                    cancelTimer(true)
                                    WPAnalytics.trackQuickStartStat(.quickStartSuggestionButtonTapped,
                                                                    properties: ["type": "negative"],
                                                                    blog: blog)
                                }
        }

        ActionDispatcher.dispatch(NoticeAction.post(notice))

        WPAnalytics.trackQuickStartStat(.quickStartSuggestionViewed, blog: blog)
    }

    /// Prepares to begin the specified tour.
    ///
    /// - Parameters:
    ///     - tour: the tour to prepare for running.
    ///     - blog: the blog in which the tour will take place.
    ///
    func prepare(tour: QuickStartTour, for blog: Blog) {
        endCurrentTour()
        dismissSuggestion()

        let adjustedTour = addSiteMenuWayPointIfNeeded(for: tour)

        switch adjustedTour {
        case let adjustedTour as QuickStartFollowTour:
            adjustedTour.setupReaderTab()
            fallthrough
        default:
            currentTourState = TourState(tour: adjustedTour, blog: blog, step: 0)
        }
    }

    /// Posts a notification to trigger updates to Quick Start Cards if needed.
    func refreshQuickStart() {
        NotificationCenter.default.post(name: .QuickStartTourElementChangedNotification,
                                        object: self,
                                        userInfo: [QuickStartTourGuide.notificationElementKey: QuickStartTourElement.updateQuickStart])
    }

    func dismissTaskCompleteNotice() {
        ActionDispatcher.dispatch(NoticeAction.clearWithTag(noticeCompleteTag))
    }

    private func addSiteMenuWayPointIfNeeded(for tour: QuickStartTour) -> QuickStartTour {

        if currentEntryPoint == .blogDashboard &&
            tour.mustBeShownInBlogDetails &&
            !UIDevice.isPad() {
            var tourToAdjust = tour
            let siteMenuWaypoint = QuickStartSiteMenu.waypoint
            tourToAdjust.waypoints.insert(siteMenuWaypoint, at: 0)
            return tourToAdjust
        } else {
            return tour
        }
    }

    /// Begins the prepared tour.  Should only be called after `prepare(tour:for:)`.
    ///
    func begin() {
        guard let state = currentTourState,
            state.step == 0 else {

            return
        }

        entryPointForCurrentTour = currentEntryPoint
        tourInProgress = true
        showCurrentStep()
    }

    // Required for now because obj-c doesn't know about Quick Start tours
    @objc func completeSiteIconTour(forBlog blog: Blog) {
        complete(tour: QuickStartSiteIconTour(), silentlyForBlog: blog)
    }

    @objc func completeViewSiteTour(forBlog blog: Blog) {
        complete(tour: QuickStartViewTour(blog: blog), silentlyForBlog: blog)
    }

    @objc func completeSharingTour(forBlog blog: Blog) {
        complete(tour: QuickStartShareTour(), silentlyForBlog: blog)
    }

    /// Complete the specified tour without posting a notification.
    ///
    func complete(tour: QuickStartTour, silentlyForBlog blog: Blog) {
        complete(tour: tour, for: blog, postNotification: false)
    }

    func complete(tour: QuickStartTour, for blog: Blog, postNotification: Bool = true) {
        guard let tourCount = blog.quickStartTours?.count, tourCount > 0,
              isTourAvailableToComplete(tour: tour, for: blog) else {
            // Tours haven't been set up yet or were skipped.
            // Or tour to be completed has already been completed.
            // No reason to continue.
            return
        }
        completed(tour: tour, for: blog, postNotification: postNotification)
    }

    func showCongratsNoticeIfNeeded(for blog: Blog) {
        guard allToursCompleted(for: blog), shouldShowCongratsNotice else {
            return
        }

        shouldShowCongratsNotice = false

        let noticeStyle = QuickStartNoticeStyle(attributedMessage: nil, isDismissable: true)
        let notice = Notice(title: Strings.congratulationsTitle,
                            message: Strings.congratulationsMessage,
                            style: noticeStyle,
                            tag: noticeTag)

        ActionDispatcher.dispatch(NoticeAction.post(notice))

        WPAnalytics.trackQuickStartStat(.quickStartCongratulationsViewed, blog: blog)
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
        guard let currentElement = currentElement(),
            let tourState = currentTourState else {
            return
        }
        if element != currentElement {
            let blogDetailEvents: [QuickStartTourElement] = [.blogDetailNavigation, .checklist, .themes, .viewSite, .sharing, .siteMenu]
            let readerElements: [QuickStartTourElement] = [.readerTab, .readerDiscoverSettings]

            if blogDetailEvents.contains(element) {
                endCurrentTour()
            } else if element == .tabFlipped, !readerElements.contains(currentElement) {
                endCurrentTour()
            }
            return
        }

        dismissCurrentNotice()

        guard let nextStep = getNextStep() else {
            showTaskCompleteNoticeIfNeeded(for: tourState.tour)
            entryPointForCurrentTour = .unknown
            completed(tour: tourState.tour, for: tourState.blog)
            currentTourState = nil

            // TODO: we could put a nice animation here
            return
        }

        if element == .siteMenu {
            showNextStepWithDelay(nextStep)
        } else {
            showNextStep(nextStep)
        }
    }

    private func showTaskCompleteNoticeIfNeeded(for tour: QuickStartTour) {

        guard let taskCompleteDescription = tour.taskCompleteDescription else {
            return
        }

        let noticeStyle = QuickStartNoticeStyle(attributedMessage: taskCompleteDescription, isDismissable: true)
        let notice = Notice(title: "", style: noticeStyle, tag: noticeCompleteTag)

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.quickStartDelay) {
            ActionDispatcher.dispatch(NoticeAction.post(notice))
        }
    }

    private func showNextStep(_ nextStep: TourState) {
        currentTourState = nextStep
        showCurrentStep()
    }

    private func showNextStepWithDelay(_ nextStep: TourState) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.nextStepDelay) {
            self.currentTourState = nextStep
            self.showCurrentStep()
        }
    }

    static func countChecklistCompleted(in list: [QuickStartTour], for blog: Blog) -> Int {
        let allChecklistTourIDs =  list.map { $0.key }
        let completedTourIDs = (blog.completedQuickStartTours ?? []).map { $0.tourID }
        let filteredIDs = allChecklistTourIDs.filter { completedTourIDs.contains($0) }
        return Set(filteredIDs).count
    }

    func countChecklistCompleted(in list: [QuickStartTour], for blog: Blog) -> Int {
        return QuickStartTourGuide.countChecklistCompleted(in: list, for: blog)
    }

    func endCurrentTour() {
        dismissCurrentNotice()
        currentTourState = nil
    }
}

private extension QuickStartTourGuide {

    func completed(tour: QuickStartTour, for blog: Blog, postNotification: Bool = true) {
        let completedTourIDs = (blog.completedQuickStartTours ?? []).map { $0.tourID }
        guard !completedTourIDs.contains(tour.key) else {
            return
        }

        blog.completeTour(tour.key)

        // Create a site is completed automatically, we don't want to track
        if tour.analyticsKey != "create_site" {
            WPAnalytics.trackQuickStartStat(.quickStartTourCompleted,
                                            properties: ["task_name": tour.analyticsKey],
                                            blog: blog)
        }

        if postNotification {
            NotificationCenter.default.post(name: .QuickStartTourElementChangedNotification, object: self, userInfo: [QuickStartTourGuide.notificationElementKey: QuickStartTourElement.tourCompleted])

            recentlyTouredBlog = blog
        } else {
            recentlyTouredBlog = nil
        }

        if allToursCompleted(for: blog) {
            WPAnalytics.trackQuickStartStat(.quickStartAllToursCompleted, blog: blog)
            grantCongratulationsAward(for: blog)
            tourInProgress = false
            shouldShowCongratsNotice = true
        } else {
            if let nextTour = tourToSuggest(for: blog) {
                PushNotificationsManager.shared.postNotification(for: nextTour, quickStartType: blog.quickStartType)
            }
        }
    }

    /// Check if all the tours have been completed
    ///
    /// - Parameter blog: blog to check
    /// - Returns: boolean, true if all tours have been completed
    func allToursCompleted(for blog: Blog) -> Bool {
        let list = QuickStartFactory.allTours(for: blog)
        return countChecklistCompleted(in: list, for: blog) >= list.count
    }

    /// Returns a list of all available tours that have not yet been completed
    /// - Parameter blog: blog to check
    func uncompletedTours(for blog: Blog) -> [QuickStartTour] {
        let completedTours: [QuickStartTourState] = blog.completedQuickStartTours ?? []
        let allTours = QuickStartFactory.allTours(for: blog)
        let completedIDs = completedTours.map { $0.tourID }
        let uncompletedTours = allTours.filter { !completedIDs.contains($0.key) }
        return uncompletedTours
    }

    /// Check if the provided tour have not yet been completed and is available to complete
    /// - Parameters:
    ///   - tour: tour to check
    ///   - blog: blog to check
    /// - Returns: boolean, true if the tour is not completed and is available. False otherwise
    func isTourAvailableToComplete(tour: QuickStartTour, for blog: Blog) -> Bool {
        let uncompletedTours = uncompletedTours(for: blog)
        return uncompletedTours.contains { element in
            element.key == tour.key
        }
    }

    func showCurrentStep() {
        guard let waypoint = currentWaypoint() else {
            return
        }

        if let state = currentTourState,
            state.tour.showWaypointNotices {
            showStepNotice(waypoint.description)
        }

        let userInfo: [String: Any] = [
            QuickStartTourGuide.notificationElementKey: waypoint.element,
            QuickStartTourGuide.notificationDescriptionKey: waypoint.description
            ]

        NotificationCenter.default.post(name: .QuickStartTourElementChangedNotification, object: self, userInfo: userInfo)
    }

    func showStepNotice(_ description: NSAttributedString) {
        let noticeStyle = QuickStartNoticeStyle(attributedMessage: description)
        let notice = Notice(title: "Test Quick Start Notice", style: noticeStyle, tag: noticeTag)
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
        guard currentSuggestion != nil else {
            return
        }

        tourInProgress = false
        currentSuggestion = nil
        ActionDispatcher.dispatch(NoticeAction.clearWithTag(noticeTag))
    }

    func getNextStep() -> TourState? {
        guard let tourState = currentTourState,
            tourState.step + 1 < tourState.tour.waypoints.count else {
                return nil
        }

        return TourState(tour: tourState.tour, blog: tourState.blog, step: tourState.step + 1)
    }

    func skipped(_ tour: QuickStartTour, for blog: Blog) {
        tourInProgress = false
        blog.skipTour(tour.key)
        recentlyTouredBlog = nil
    }

    // - TODO: Research if dispatching `NoticeAction.empty` is still necessary now that we use `.clearWithTag`.
    func dismissCurrentNotice() {
        ActionDispatcher.dispatch(NoticeAction.clearWithTag(noticeTag))
        ActionDispatcher.dispatch(NoticeAction.clearWithTag(noticeCompleteTag))
        ActionDispatcher.dispatch(NoticeAction.empty)
        NotificationCenter.default.post(name: .QuickStartTourElementChangedNotification, object: self, userInfo: [QuickStartTourGuide.notificationElementKey: QuickStartTourElement.noSuchElement])
    }

    private func grantCongratulationsAward(for blog: Blog) {
        let service = SiteManagementService(coreDataStack: ContextManager.sharedInstance())
        service.markQuickStartChecklistAsComplete(for: blog)
    }

    private struct Constants {
        static let suggestionTimeout = 10.0
        static let quickStartDelay: DispatchTimeInterval = .milliseconds(500)
        static let nextStepDelay: DispatchTimeInterval = .milliseconds(1000)
    }

    private enum Strings {
        static let congratulationsTitle = NSLocalizedString("Congrats! You know your way around", comment: "Title shown when all tours have been completed.")
        static let congratulationsMessage = NSLocalizedString("Doesn't it feel good to cross things off a list?", comment: "Message shown when all tours have been completed")
    }
}

internal extension NSNotification.Name {
    static let QuickStartTourElementChangedNotification = NSNotification.Name(rawValue: "QuickStartTourElementChangedNotification")
}

private struct TourState {
    var tour: QuickStartTour
    var blog: Blog
    var step: Int
}
