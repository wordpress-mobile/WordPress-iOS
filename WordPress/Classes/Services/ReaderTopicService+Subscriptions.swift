import Foundation
import WordPressKit

private enum SubscriptionAction {
    case notifications(siteId: Int)
    case postsEmail(siteId: Int)
    case updatePostsEmail(siteId: Int, frequency: ReaderServiceDeliveryFrequency)
    case comments(siteId: Int)
}

extension ReaderTopicService {
    // MARK: Private methods

    private func apiRequest() -> WordPressComRestApi {
        let api = coreDataStack.performQuery { context in
            try? WPAccount.lookupDefaultWordPressComAccount(in: context)?.wordPressComRestApi
        }
        if let api, api.hasCredentials() {
            return api
        }

        return WordPressComRestApi.defaultApi(oAuthToken: nil, userAgent: WPUserAgent.wordPress())
    }

    private func fetchSiteTopic(with siteId: Int, in context: NSManagedObjectContext, _ failure: @escaping (ReaderTopicServiceError?) -> Void) -> ReaderSiteTopic? {
        guard let siteTopic = try? ReaderSiteTopic.lookup(withSiteID: NSNumber(value: siteId), in: context) else {
            failure(.topicNotfound(id: siteId))
            return nil
        }

        if siteTopic.postSubscription == nil {
            siteTopic.postSubscription = NSEntityDescription.insertNewObject(forEntityName: ReaderSiteInfoSubscriptionPost.classNameWithoutNamespaces(),
                                                                             into: context) as? ReaderSiteInfoSubscriptionPost
        }

        if siteTopic.emailSubscription == nil {
            siteTopic.emailSubscription = NSEntityDescription.insertNewObject(forEntityName: ReaderSiteInfoSubscriptionEmail.classNameWithoutNamespaces(),
                                                                              into: context) as? ReaderSiteInfoSubscriptionEmail
        }

        return siteTopic
    }

    private func remoteAction(for action: SubscriptionAction, _ subscribe: Bool, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        let service = ReaderTopicServiceRemote(wordPressComRestApi: apiRequest())

        switch action {
        case .notifications(let siteId):
            if subscribe {
                service.subscribeSiteNotifications(with: siteId, {
                    WPAnalytics.trackReader(.followedBlogNotificationsReaderMenuOn, properties: ["blogId": siteId])
                    success()
                }, failure)
            } else {
                service.unsubscribeSiteNotifications(with: siteId, {
                    WPAnalytics.trackReader(.followedBlogNotificationsReaderMenuOff, properties: ["blog_id": siteId])
                    success()
                }, failure)
            }

        case .postsEmail(let siteId):
            if subscribe {
                service.subscribePostsEmail(with: siteId, success, failure)
            } else {
                service.unsubscribePostsEmail(with: siteId, success, failure)
            }

        case .updatePostsEmail(let siteId, let frequency):
            service.updateFrequencyPostsEmail(with: siteId, frequency: frequency, success, failure)

        case .comments(let siteId):
            if subscribe {
                service.subscribeSiteComments(with: siteId, success, failure)
            } else {
                service.unsubscribeSiteComments(with: siteId, success, failure)
            }
        }
    }
}

extension ReaderTopicService {
    /// Toggle site notifications subscription for new post
    ///
    /// - Parameters:
    ///   - siteId: Site id to be used
    ///   - subscribe: Flag to define is subscribe or unsubscribe
    ///   - success: Success block
    ///   - failure: Failure block
    func toggleSubscribingNotifications(for siteId: Int?, subscribe: Bool, _ success: (() -> Void)? = nil, _ failure: ((ReaderTopicServiceError?) -> Void)? = nil) {
        guard let siteId = siteId else {
            failure?(.invalidId)
            return
        }

        let successBlock = {
            success?()
            DDLogInfo("Success turn notifications \(subscribe ? "on" : "off")")
        }

        let failureBlock = { (error: ReaderTopicServiceError?) in
            failure?(error)
            DDLogError("Error turn on notifications: \(error?.description ?? "unknown error")")
        }

        coreDataStack.performAndSave { context in
            self.toggleSiteNotifications(with: siteId, subscribe: subscribe, in: context, successBlock, failureBlock)
        }
    }

    // MARK: Private methods

    private func toggleSiteNotifications(with siteId: Int, subscribe: Bool = false, in context: NSManagedObjectContext, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        guard let siteTopic = fetchSiteTopic(with: siteId, in: context, failure),
            let postSubscription = siteTopic.postSubscription else {
            return
        }

        let oldValue = postSubscription.sendPosts
        postSubscription.sendPosts = subscribe

        let failureBlock = { (error: ReaderTopicServiceError?) in
            self.coreDataStack.performAndSave({ context in
                guard let siteTopic = try? ReaderSiteTopic.lookup(withSiteID: NSNumber(value: siteId), in: context) else {
                    failure(.topicNotfound(id: siteId))
                    return
                }
                siteTopic.postSubscription?.sendPosts = oldValue
            }, completion: {
                failure(error)
            }, on: .main)
        }

        remoteAction(for: .notifications(siteId: siteId), subscribe, success, failureBlock)
    }
}

extension ReaderTopicService {
    /// Toggle site notifications subscription for new comments
    ///
    /// - Parameters:
    ///   - siteId: Site id to be used
    ///   - subscribe: Flag to define is subscribe or unsubscribe
    ///   - success: Success block
    ///   - failure: Failure block
    func toggleSubscribingComments(for siteId: Int?, subscribe: Bool, _ success: (() -> Void)? = nil, _ failure: ((ReaderTopicServiceError?) -> Void)? = nil) {
        guard let siteId = siteId else {
            failure?(.invalidId)
            return
        }

        let successBlock = {
            success?()
            DDLogInfo("Success turn notifications \(subscribe ? "on" : "off")")

            let event: WPAnalyticsStat = subscribe ? .notificationsSettingsCommentsNotificationsOn : .notificationsSettingsCommentsNotificationsOff
            WPAnalytics.track(event)
        }

        let failureBlock = { (error: ReaderTopicServiceError?) in
            failure?(error)
            DDLogError("Error turn on notifications: \(error?.description ?? "unknown error")")
        }

        coreDataStack.performAndSave { context in
            self.togglePostComments(with: siteId, subscribe: subscribe, in: context, successBlock, failureBlock)
        }
    }

    // MARK: Private methods

    private func togglePostComments(with siteId: Int, subscribe: Bool = false, in context: NSManagedObjectContext, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        guard let siteTopic = fetchSiteTopic(with: siteId, in: context, failure),
            let emailSubscription = siteTopic.emailSubscription else {
            return
        }

        let oldValue = emailSubscription.sendComments
        emailSubscription.sendComments = subscribe

        let failureBlock = { (error: ReaderTopicServiceError?) in
            self.coreDataStack.performAndSave({ context in
                guard let siteTopic = try? ReaderSiteTopic.lookup(withSiteID: NSNumber(value: siteId), in: context) else {
                    failure(.topicNotfound(id: siteId))
                    return
                }
                siteTopic.emailSubscription?.sendComments = oldValue
            }, completion: {
                failure(error)
            }, on: .main)
        }

        remoteAction(for: .comments(siteId: siteId), subscribe, success, failureBlock)
    }
}

extension ReaderTopicService {
    /// Toggle email site notifications subscription for new post
    ///
    /// - Parameters:
    ///   - siteId: Site id to be used
    ///   - subscribe: Flag to define is subscribe or unsubscribe
    ///   - success: Success block
    ///   - failure: Failure block
    func toggleSubscribingEmail(for siteId: Int?, subscribe: Bool, _ success: (() -> Void)? = nil, _ failure: ((ReaderTopicServiceError?) -> Void)? = nil) {
        guard let siteId = siteId else {
            failure?(.invalidId)
            return
        }

        let successBlock = {
            success?()
            DDLogInfo("Success turn notifications \(subscribe ? "on" : "off")")

            let event: WPAnalyticsStat = subscribe ? .notificationsSettingsEmailNotificationsOn : .notificationsSettingsEmailNotificationsOff
            WPAnalytics.track(event)
        }

        let failureBlock = { (error: ReaderTopicServiceError?) in
            failure?(error)
            DDLogError("Error turn on notifications: \(error?.description ?? "unknown error")")
        }

        coreDataStack.performAndSave { context in
            self.togglePostsEmail(with: siteId, subscribe: subscribe, in: context, successBlock, failureBlock)
        }
    }

    /// Update email site notifications subscription frequency
    ///
    /// - Parameters:
    ///   - siteId: Site id to be used
    ///   - frequency: The frequency value
    ///   - success: Success block
    ///   - failure: Failure block
    func updateFrequencyPostsEmail(with siteId: Int, frequency: ReaderServiceDeliveryFrequency, _ success: (() -> Void)? = nil, _ failure: ((ReaderTopicServiceError?) -> Void)? = nil) {
        let successBlock = { [weak self] in
            success?()
            DDLogInfo("Success update frequency \(frequency.rawValue)")

            if let event = self?.frequencyPostsEmailTrackEvent(for: frequency) {
                WPAnalytics.track(event)
            }
        }

        let failureBlock = { (error: ReaderTopicServiceError?) in
            failure?(error)
            DDLogError("Error turn on notifications: \(error?.description ?? "unknown error")")
        }

        coreDataStack.performAndSave { context in
            self.updatePostsEmail(with: siteId, frequency: frequency, in: context, successBlock, failureBlock)
        }
    }

    // MARK: Private methods

    private func frequencyPostsEmailTrackEvent(for frequency: ReaderServiceDeliveryFrequency) -> WPAnalyticsStat {
        switch frequency {
        case .daily:
            return .notificationsSettingsEmailDeliveryDaily

        case .instantly:
            return .notificationsSettingsEmailDeliveryInstantly

        case .weekly:
            return .notificationsSettingsEmailDeliveryWeekly
        }
    }

    private func togglePostsEmail(with siteId: Int, subscribe: Bool = false, in context: NSManagedObjectContext, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        guard let siteTopic = fetchSiteTopic(with: siteId, in: context, failure),
            let emailSubscription = siteTopic.emailSubscription else {
            return
        }

        let oldValue = emailSubscription.sendPosts
        emailSubscription.sendPosts = subscribe

        let failureBlock = { (error: ReaderTopicServiceError?) in
            self.coreDataStack.performAndSave({ context in
                guard let siteTopic = try? ReaderSiteTopic.lookup(withSiteID: NSNumber(value: siteId), in: context) else {
                    failure(nil)
                    return
                }
                siteTopic.emailSubscription?.sendPosts = oldValue
            }, completion: {
                failure(error)
            }, on: .main)
        }

        remoteAction(for: .postsEmail(siteId: siteId), subscribe, success, failureBlock)
    }

    private func updatePostsEmail(with siteId: Int, frequency: ReaderServiceDeliveryFrequency, in context: NSManagedObjectContext, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        guard let siteTopic = fetchSiteTopic(with: siteId, in: context, failure),
            let emailSubscription = siteTopic.emailSubscription else {
            return
        }

        let oldValue = emailSubscription.postDeliveryFrequency
        emailSubscription.postDeliveryFrequency = frequency.rawValue

        let failureBlock = { (error: ReaderTopicServiceError?) in
            self.coreDataStack.performAndSave({ context in
                guard let siteTopic = try? ReaderSiteTopic.lookup(withSiteID: NSNumber(value: siteId), in: context) else {
                    failure(.topicNotfound(id: siteId))
                    return
                }
                siteTopic.emailSubscription?.postDeliveryFrequency = oldValue
            }, completion: {
                failure(error)
            }, on: .main)
        }

        remoteAction(for: .updatePostsEmail(siteId: siteId, frequency: frequency), false, success, failureBlock)
    }
}
