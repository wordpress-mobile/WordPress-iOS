import Foundation
import CocoaLumberjack
import WordPressKit

struct BlogJetpackSettingsService {

    fileprivate let context: NSManagedObjectContext

    init(managedObjectContext context: NSManagedObjectContext) {
        self.context = context
    }

    /// Sync ALL the Jetpack settings for a blog
    ///
    func syncJetpackSettingsForBlog(_ blog: Blog, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {

        guard blog.supports(.jetpackSettings) else {
            success()
            return
        }

        context.perform {
            guard let blogInContext = self.context.object(with: blog.objectID) as? Blog,
                let remote = BlogJetpackSettingsServiceRemote(wordPressComRestApi: blog.wordPressComRestApi()),
                let blogDotComId = blogInContext.dotComID as? Int,
                let blogSettings = blogInContext.settings else {
                    success()
                    return
            }

            var successfulFetches = 0
            var fetchError: Error? = nil
            var remoteJetpackSettings: RemoteBlogJetpackSettings? = nil
            var remoteJetpackMonitorSettings: RemoteBlogJetpackMonitorSettings? = nil

            // Create a dispatch group to wait for both calls.
            let syncGroup = DispatchGroup()

            syncGroup.enter()
            remote.getJetpackSettingsForSite(blogDotComId,
                                             success: { (remoteSettings) in
                                                remoteJetpackSettings = remoteSettings
                                                successfulFetches += 1
                                                syncGroup.leave()
                                             }, failure: { (error) in
                                                fetchError = error
                                                syncGroup.leave()
                                             })

            syncGroup.enter()
            remote.getJetpackMonitorSettingsForSite(blogDotComId,
                                                    success: { (remoteMonitorSettings) in
                                                        remoteJetpackMonitorSettings = remoteMonitorSettings
                                                        successfulFetches += 1
                                                        syncGroup.leave()
                                                    }, failure: { (error) in
                                                        fetchError = error
                                                        syncGroup.leave()
                                                    })

            syncGroup.notify(queue: DispatchQueue.main, execute: {
                guard let remoteJetpackSettings = remoteJetpackSettings,
                    let remoteJetpackMonitorSettings = remoteJetpackMonitorSettings else {
                        failure(nil)
                        return
                }
                if successfulFetches == 2 {
                    self.context.perform {
                        self.updateJetpackSettings(blogSettings, remoteSettings: remoteJetpackSettings)
                        self.updateJetpackMonitorSettings(blogSettings, remoteSettings: remoteJetpackMonitorSettings)
                    }
                    do {
                        try self.context.save()
                        success()
                    } catch let error as NSError {
                        failure(error)
                    }
                } else {
                    failure(fetchError)
                }
            })
        }
    }

    // Jetpack settings have to be updated one by one because the API does not allow us to do it in any other way.

    func updateJetpackMonitorEnabledForBlog(_ blog: Blog, value: Bool, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        updateJetpackSettingForBlog(blog,
                                    key: BlogJetpackSettingsServiceRemote.Keys.monitorEnabledKey,
                                    value: value as AnyObject,
                                    success: success,
                                    failure: failure)
    }

    func updateBlockMaliciousLoginAttemptsForBlog(_ blog: Blog, value: Bool, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        updateJetpackSettingForBlog(blog,
                                    key: BlogJetpackSettingsServiceRemote.Keys.blockMaliciousLoginAttemptsKey,
                                    value: value as AnyObject,
                                    success: success,
                                    failure: failure)
    }

    func updateWhiteListedIPAddressesForBlog(_ blog: Blog, value: Set<String>, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        let joinedIPs = value.joined(separator: ", ")
        updateJetpackSettingForBlog(blog,
                                    key: BlogJetpackSettingsServiceRemote.Keys.whiteListedIPAddressesKey,
                                    value: joinedIPs as AnyObject,
                                    success: success,
                                    failure: failure)
    }

    func updateSSOEnabledForBlog(_ blog: Blog, value: Bool, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        updateJetpackSettingForBlog(blog,
                                    key: BlogJetpackSettingsServiceRemote.Keys.sSOEnabledKey,
                                    value: value as AnyObject,
                                    success: success,
                                    failure: failure)
    }

    func updateSSOMatchAccountsByEmailForBlog(_ blog: Blog, value: Bool, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        updateJetpackSettingForBlog(blog,
                                    key: BlogJetpackSettingsServiceRemote.Keys.sSOMatchAccountsByEmailKey,
                                    value: value as AnyObject,
                                    success: success,
                                    failure: failure)
    }

    func updateSSORequireTwoStepAuthenticationForBlog(_ blog: Blog, value: Bool, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        updateJetpackSettingForBlog(blog,
                                    key: BlogJetpackSettingsServiceRemote.Keys.sSORequireTwoStepAuthenticationKey,
                                    value: value as AnyObject,
                                    success: success,
                                    failure: failure)
    }

    func updateJetpackMonitorSettinsForBlog(_ blog: Blog, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        context.perform {

            guard let blogInContext = self.context.object(with: blog.objectID) as? Blog,
                let remote = BlogJetpackSettingsServiceRemote(wordPressComRestApi: blog.wordPressComRestApi()),
                let blogDotComId = blogInContext.dotComID as? Int else {
                    failure(nil)
                    return
            }

            remote.updateJetpackMonitorSettingsForSite(blogDotComId,
                                                       settings: self.jetpackMonitorsSettingsRemote(blogInContext.settings!),
                                                       success: { () in
                                                           do {
                                                               try self.context.save()
                                                               success()
                                                           } catch let error as NSError {
                                                               failure(error)
                                                           }
                                                       }, failure: { (error) in
                                                           failure(error)
                                                       })
        }
    }

}

private extension BlogJetpackSettingsService {

    func updateJetpackSettingForBlog(_ blog: Blog, key: String, value: AnyObject, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        context.perform {

            guard let blogInContext = self.context.object(with: blog.objectID) as? Blog,
                let remote = BlogJetpackSettingsServiceRemote(wordPressComRestApi: blog.wordPressComRestApi()),
                let blogDotComId = blogInContext.dotComID as? Int else {
                    failure(nil)
                    return
            }

            remote.updateJetpackSetting(blogDotComId,
                                        key: key,
                                        value: value,
                                        success: { () in
                                            do {
                                                try self.context.save()
                                                success()
                                            } catch let error as NSError {
                                                failure(error)
                                            }
                                        }, failure: { (error) in
                                            failure(error)
                                        })
        }
    }

    func updateJetpackSettings(_ settings: BlogSettings, remoteSettings: RemoteBlogJetpackSettings) {
        settings.jetpackMonitorEnabled = remoteSettings.monitorEnabled
        settings.jetpackBlockMaliciousLoginAttempts = remoteSettings.blockMaliciousLoginAttempts
        settings.jetpackLoginWhiteListedIPAddresses = remoteSettings.loginWhiteListedIPAddresses
        settings.jetpackSSOEnabled = remoteSettings.sSOEnabled
        settings.jetpackSSOMatchAccountsByEmail = remoteSettings.sSOMatchAccountsByEmail
        settings.jetpackSSORequireTwoStepAuthentication = remoteSettings.sSORequireTwoStepAuthentication
    }

    func updateJetpackMonitorSettings(_ settings: BlogSettings, remoteSettings: RemoteBlogJetpackMonitorSettings) {
        settings.jetpackMonitorEmailNotifications = remoteSettings.monitorEmailNotifications
        settings.jetpackMonitorPushNotifications = remoteSettings.monitorPushNotifications
    }

    func jetpackMonitorsSettingsRemote(_ settings: BlogSettings) -> RemoteBlogJetpackMonitorSettings {
        return RemoteBlogJetpackMonitorSettings(monitorEmailNotifications: settings.jetpackMonitorEmailNotifications,
                                                monitorPushNotifications: settings.jetpackMonitorPushNotifications)
    }

}
