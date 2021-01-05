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
        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let defaultAccount = accountService.defaultWordPressComAccount()
        if let api = defaultAccount?.wordPressComRestApi, api.hasCredentials() {
            return api
        }

        return WordPressComRestApi.defaultApi(oAuthToken: nil, userAgent: WPUserAgent.wordPress())
    }

    private func fetchSiteTopic(with siteId: Int, _ failure: @escaping (ReaderTopicServiceError?) -> Void) -> ReaderSiteTopic? {
        guard let siteTopic = findSiteTopic(withSiteID: NSNumber(value: siteId)) else {
            failure(.topicNotfound(id: siteId))
            return nil
        }

        if siteTopic.postSubscription == nil {
            siteTopic.postSubscription = NSEntityDescription.insertNewObject(forEntityName: ReaderSiteInfoSubscriptionPost.classNameWithoutNamespaces(),
                                                                             into: managedObjectContext) as? ReaderSiteInfoSubscriptionPost
        }

        if siteTopic.emailSubscription == nil {
            siteTopic.emailSubscription = NSEntityDescription.insertNewObject(forEntityName: ReaderSiteInfoSubscriptionEmail.classNameWithoutNamespaces(),
                                                                              into: managedObjectContext) as? ReaderSiteInfoSubscriptionEmail
        }

        ContextManager.sharedInstance().saveContextAndWait(managedObjectContext)

        return siteTopic
    }

    private func remoteAction(for action: SubscriptionAction, _ subscribe: Bool, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        let service = ReaderTopicServiceRemote(wordPressComRestApi: apiRequest())

        let successBlock = {
            ContextManager.sharedInstance().save(self.managedObjectContext, withCompletionBlock: success)
        }

        switch action {
        case .notifications(let siteId):
            if subscribe {
                service.subscribeSiteNotifications(with: siteId, {
                    WPAnalytics.trackReader(.followedBlogNotificationsReaderMenuOn, properties: ["blogId": siteId])
                    successBlock()
                }, failure)
            } else {
                service.unsubscribeSiteNotifications(with: siteId, {
                    WPAnalytics.trackReader(.followedBlogNotificationsReaderMenuOff, properties: ["blog_id": siteId])
                    successBlock()
                }, failure)
            }

        case .postsEmail(let siteId):
            if subscribe {
                service.subscribePostsEmail(with: siteId, successBlock, failure)
            } else {
                service.unsubscribePostsEmail(with: siteId, successBlock, failure)
            }

        case .updatePostsEmail(let siteId, let frequency):
            service.updateFrequencyPostsEmail(with: siteId, frequency: frequency, successBlock, failure)

        case .comments(let siteId):
            if subscribe {
                service.subscribeSiteComments(with: siteId, successBlock, failure)
            } else {
                service.unsubscribeSiteComments(with: siteId, successBlock, failure)
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

        toggleSiteNotifications(with: siteId, subscribe: subscribe, successBlock, failureBlock)
    }


    // MARK: Private methods

    private func toggleSiteNotifications(with siteId: Int, subscribe: Bool = false, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        guard let siteTopic = fetchSiteTopic(with: siteId, failure),
            let postSubscription = siteTopic.postSubscription else {
            return
        }

        let oldValue = postSubscription.sendPosts
        postSubscription.sendPosts = subscribe

        let failureBlock = { (error: ReaderTopicServiceError?) in
            guard let siteTopic = self.findSiteTopic(withSiteID: NSNumber(value: siteId)) else {
                failure(.topicNotfound(id: siteId))
                return
            }
            siteTopic.postSubscription?.sendPosts = oldValue
            ContextManager.sharedInstance().save(self.managedObjectContext) {
                failure(error)
            }
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

        togglePostComments(with: siteId, subscribe: subscribe, successBlock, failureBlock)
    }


    // MARK: Private methods

    private func togglePostComments(with siteId: Int, subscribe: Bool = false, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        guard let siteTopic = fetchSiteTopic(with: siteId, failure),
            let emailSubscription = siteTopic.emailSubscription else {
            return
        }

        let oldValue = emailSubscription.sendComments
        emailSubscription.sendComments = subscribe

        let failureBlock = { (error: ReaderTopicServiceError?) in
            guard let siteTopic = self.findSiteTopic(withSiteID: NSNumber(value: siteId)) else {
                failure(.topicNotfound(id: siteId))
                return
            }
            siteTopic.emailSubscription?.sendComments = oldValue
            ContextManager.sharedInstance().save(self.managedObjectContext) {
                failure(error)
            }
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

        togglePostsEmail(with: siteId, subscribe: subscribe, successBlock, failureBlock)
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
        updatePostsEmail(with: siteId, frequency: frequency, successBlock, failureBlock)
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

    private func togglePostsEmail(with siteId: Int, subscribe: Bool = false, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        guard let siteTopic = fetchSiteTopic(with: siteId, failure),
            let emailSubscription = siteTopic.emailSubscription else {
            return
        }

        let oldValue = emailSubscription.sendPosts
        emailSubscription.sendPosts = subscribe

        let failureBlock = { (error: ReaderTopicServiceError?) in
            guard let siteTopic = self.findSiteTopic(withSiteID: NSNumber(value: siteId)) else {
                failure(nil)
                return
            }
            siteTopic.emailSubscription?.sendPosts = oldValue
            ContextManager.sharedInstance().save(self.managedObjectContext) {
                failure(error)
            }
        }

        remoteAction(for: .postsEmail(siteId: siteId), subscribe, success, failureBlock)
    }

    private func updatePostsEmail(with siteId: Int, frequency: ReaderServiceDeliveryFrequency, _ success: @escaping () -> Void, _ failure: @escaping (ReaderTopicServiceError?) -> Void) {
        guard let siteTopic = fetchSiteTopic(with: siteId, failure),
            let emailSubscription = siteTopic.emailSubscription else {
            return
        }

        let oldValue = emailSubscription.postDeliveryFrequency
        emailSubscription.postDeliveryFrequency = frequency.rawValue

        let failureBlock = { (error: ReaderTopicServiceError?) in
            guard let siteTopic = self.findSiteTopic(withSiteID: NSNumber(value: siteId)) else {
                failure(.topicNotfound(id: siteId))
                return
            }
            siteTopic.emailSubscription?.postDeliveryFrequency = oldValue
            ContextManager.sharedInstance().save(self.managedObjectContext) {
                failure(error)
            }
        }

        remoteAction(for: .updatePostsEmail(siteId: siteId, frequency: frequency), false, success, failureBlock)
    }
}
