import Foundation
import CocoaLumberjack
import WordPressKit

struct BlogJetpackSettingsService {

    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    /// Sync ALL the Jetpack settings for a blog
    ///
    func syncJetpackSettingsForBlog(_ blog: Blog, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        guard blog.supports(.jetpackSettings) else {
            success()
            return
        }
        guard let remoteAPI = blog.wordPressComRestApi(),
            let blogDotComId = blog.dotComID as? Int
        else {
            failure(nil)
            return
        }

        var fetchError: Error? = nil
        var remoteJetpackSettings: RemoteBlogJetpackSettings? = nil
        var remoteJetpackMonitorSettings: RemoteBlogJetpackMonitorSettings? = nil
        let remote = BlogJetpackSettingsServiceRemote(wordPressComRestApi: remoteAPI)

        // Create a dispatch group to wait for both calls.
        let syncGroup = DispatchGroup()

        syncGroup.enter()
        remote.getJetpackSettingsForSite(blogDotComId,
                                         success: { (remoteSettings) in
                                             remoteJetpackSettings = remoteSettings
                                             syncGroup.leave()
                                         },
                                         failure: { (error) in
                                             fetchError = error
                                             syncGroup.leave()
                                         })

        syncGroup.enter()
        remote.getJetpackMonitorSettingsForSite(blogDotComId,
                                                success: { (remoteMonitorSettings) in
                                                    remoteJetpackMonitorSettings = remoteMonitorSettings
                                                    syncGroup.leave()
                                                },
                                                failure: { (error) in
                                                    fetchError = error
                                                    syncGroup.leave()
                                                })

        syncGroup.notify(queue: DispatchQueue.main, execute: {
            guard let remoteJetpackSettings = remoteJetpackSettings,
                let remoteJetpackMonitorSettings = remoteJetpackMonitorSettings else {
                    failure(fetchError)
                    return
            }

            self.coreDataStack.performAndSave({ context in
                guard let blogSettings = Blog.lookup(withObjectID: blog.objectID, in: context)?.settings else {
                    return
                }

                self.updateJetpackSettings(blogSettings, remoteSettings: remoteJetpackSettings)
                self.updateJetpackMonitorSettings(blogSettings, remoteSettings: remoteJetpackMonitorSettings)
            }, completion: success)
        })
    }

    /// Sync ALL the Jetpack Modules settings for a blog
    ///
    func syncJetpackModulesForBlog(_ blog: Blog, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        guard blog.supports(.jetpackSettings) else {
            success()
            return
        }
        guard let remoteAPI = blog.wordPressComRestApi(),
            let blogDotComId = blog.dotComID as? Int
        else {
            failure(nil)
            return
        }

        let remote = BlogJetpackSettingsServiceRemote(wordPressComRestApi: remoteAPI)
        remote.getJetpackModulesSettingsForSite(
            blogDotComId,
            success: { (remoteModulesSettings) in
                self.coreDataStack.performAndSave({ context in
                    guard let blogSettings = Blog.lookup(withObjectID: blog.objectID, in: context)?.settings else {
                        return
                    }
                    self.updateJetpackModulesSettings(blogSettings, remoteSettings: remoteModulesSettings)
                }, completion: success)
            },
            failure: failure
        )
    }

    func updateJetpackSettingsForBlog(_ blog: Blog, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        guard let remoteAPI = blog.wordPressComRestApi(),
            let blogDotComId = blog.dotComID as? Int,
            let blogSettings = blog.settings
        else {
            failure(nil)
            return
        }

        let changes = blogSettings.changedValues()
        let remote = BlogJetpackSettingsServiceRemote(wordPressComRestApi: remoteAPI)
        remote.updateJetpackSettingsForSite(
            blogDotComId,
            settings: jetpackSettingsRemote(blogSettings),
            success: {
                self.coreDataStack.performAndSave({ context in
                    guard let blogSettings = Blog.lookup(withObjectID: blog.objectID, in: context)?.settings else {
                        return
                    }
                    for (key, value) in changes {
                        blogSettings.setValue(value, forKey: key)
                    }
                }, completion: success)
            },
            failure: failure
        )
    }

    func updateJetpackMonitorSettingsForBlog(_ blog: Blog, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        guard let remoteAPI = blog.wordPressComRestApi(),
            let blogDotComId = blog.dotComID as? Int,
            let blogSettings = blog.settings
        else {
            failure(nil)
            return
        }

        let changes = blogSettings.changedValues()
        let remote = BlogJetpackSettingsServiceRemote(wordPressComRestApi: remoteAPI)
        remote.updateJetpackMonitorSettingsForSite(
            blogDotComId,
            settings: jetpackMonitorsSettingsRemote(blogSettings),
            success: {
                self.coreDataStack.performAndSave({ context in
                    guard let blogSettings = Blog.lookup(withObjectID: blog.objectID, in: context)?.settings else {
                        return
                    }
                    for (key, value) in changes {
                        blogSettings.setValue(value, forKey: key)
                    }
                }, completion: success)
            },
            failure: failure
        )
    }

    func updateJetpackLazyImagesModuleSettingForBlog(_ blog: Blog, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        guard let blogSettings = blog.settings else {
            failure(nil)
            return
        }

        let isActive = blogSettings.jetpackLazyLoadImages
        updateJetpackModuleActiveSettingForBlog(
            blog,
            module: BlogJetpackSettingsServiceRemote.Keys.lazyLoadImages,
            active: isActive,
            success: {
                self.coreDataStack.performAndSave({ context in
                    guard let blogSettingsInContext = Blog.lookup(withObjectID: blog.objectID, in: context)?.settings else {
                        return
                    }
                    blogSettingsInContext.jetpackLazyLoadImages = isActive
                }, completion: success)
            },
            failure: failure
        )
    }

    func updateJetpackServeImagesFromOurServersModuleSettingForBlog(_ blog: Blog, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        guard let blogSettings = blog.settings else {
            failure(nil)
            return
        }

        let isActive = blogSettings.jetpackServeImagesFromOurServers
        updateJetpackModuleActiveSettingForBlog(
            blog,
            module: BlogJetpackSettingsServiceRemote.Keys.serveImagesFromOurServers,
            active: isActive,
            success: {
                self.coreDataStack.performAndSave({ context in
                    guard let blogSettingsInContext = Blog.lookup(withObjectID: blog.objectID, in: context)?.settings else {
                        return
                    }
                    blogSettingsInContext.jetpackServeImagesFromOurServers = isActive
                }, completion: success)
            },
            failure: failure
        )
    }

    func updateJetpackModuleActiveSettingForBlog(_ blog: Blog, module: String, active: Bool, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        guard let remoteAPI = blog.wordPressComRestApi(),
            let blogDotComId = blog.dotComID as? Int else {
            failure(nil)
            return
        }

        let remote = BlogJetpackSettingsServiceRemote(wordPressComRestApi: remoteAPI)
        remote.updateJetpackModuleActiveSettingForSite(
            blogDotComId,
            module: module,
            active: active,
            success: success,
            failure: failure
        )
    }

    func disconnectJetpackFromBlog(_ blog: Blog, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        guard let remoteAPI = blog.wordPressComRestApi(),
            let blogDotComId = blog.dotComID as? Int else {
                failure(nil)
                return
        }

        let remote = BlogJetpackSettingsServiceRemote(wordPressComRestApi: remoteAPI)
        remote.disconnectJetpackFromSite(blogDotComId, success: success, failure: failure)
    }

}

private extension BlogJetpackSettingsService {

    func updateJetpackSettings(_ settings: BlogSettings, remoteSettings: RemoteBlogJetpackSettings) {
        settings.jetpackMonitorEnabled = remoteSettings.monitorEnabled
        settings.jetpackBlockMaliciousLoginAttempts = remoteSettings.blockMaliciousLoginAttempts
        settings.jetpackLoginAllowListedIPAddresses = remoteSettings.loginAllowListedIPAddresses
        settings.jetpackSSOEnabled = remoteSettings.ssoEnabled
        settings.jetpackSSOMatchAccountsByEmail = remoteSettings.ssoMatchAccountsByEmail
        settings.jetpackSSORequireTwoStepAuthentication = remoteSettings.ssoRequireTwoStepAuthentication
    }

    func updateJetpackMonitorSettings(_ settings: BlogSettings, remoteSettings: RemoteBlogJetpackMonitorSettings) {
        settings.jetpackMonitorEmailNotifications = remoteSettings.monitorEmailNotifications
        settings.jetpackMonitorPushNotifications = remoteSettings.monitorPushNotifications
    }

    func updateJetpackModulesSettings(_ settings: BlogSettings, remoteSettings: RemoteBlogJetpackModulesSettings) {
        settings.jetpackLazyLoadImages = remoteSettings.lazyLoadImages
        settings.jetpackServeImagesFromOurServers = remoteSettings.serveImagesFromOurServers
    }

    func jetpackSettingsRemote(_ settings: BlogSettings) -> RemoteBlogJetpackSettings {
        return RemoteBlogJetpackSettings(monitorEnabled: settings.jetpackMonitorEnabled,
                                         blockMaliciousLoginAttempts: settings.jetpackBlockMaliciousLoginAttempts,
                                         loginAllowListedIPAddresses: settings.jetpackLoginAllowListedIPAddresses ?? Set<String>(),
                                         ssoEnabled: settings.jetpackSSOEnabled,
                                         ssoMatchAccountsByEmail: settings.jetpackSSOMatchAccountsByEmail,
                                         ssoRequireTwoStepAuthentication: settings.jetpackSSORequireTwoStepAuthentication)
    }

    func jetpackMonitorsSettingsRemote(_ settings: BlogSettings) -> RemoteBlogJetpackMonitorSettings {
        return RemoteBlogJetpackMonitorSettings(monitorEmailNotifications: settings.jetpackMonitorEmailNotifications,
                                                monitorPushNotifications: settings.jetpackMonitorPushNotifications)
    }

}
