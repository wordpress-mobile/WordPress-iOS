import Foundation

extension BlogService {
    @objc public func unscheduleBloggingReminders(for blog: Blog) {
        do {
            let scheduler = try ReminderScheduleCoordinator()
            scheduler.schedule(.none, for: blog, completion: { _ in })
            // We're currently not propagating success / failure here, as it's
            // it's only used when removing blogs or accounts, and there's
            // no extra action we can take if it fails anyway.
        } catch {
            DDLogError("Could not instantiate the reminders scheduler: \(error.localizedDescription)")
        }
    }

    @objc public func updatePromptSettings(for blog: RemoteBlog?, context: NSManagedObjectContext) {
        guard let blog,
              let jsonSettings = blog.options["blogging_prompts_settings"] as? [String: Any],
              let settingsValue = jsonSettings["value"] as? [String: Any],
              JSONSerialization.isValidJSONObject(settingsValue),
              let data = try? JSONSerialization.data(withJSONObject: settingsValue),
              let remoteSettings = try? JSONDecoder().decode(RemoteBloggingPromptsSettings.self, from: data) else {
            return
        }

        let fetchRequest = BloggingPromptSettings.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "\(#keyPath(BloggingPromptSettings.siteID)) = %@", blog.blogID)
        fetchRequest.fetchLimit = 1
        let existingSettings = (try? context.fetch(fetchRequest))?.first
        let settings = existingSettings ?? BloggingPromptSettings(context: context)
        settings.configure(with: remoteSettings, siteID: blog.blogID.int32Value, context: context)
    }

    /// Synchronizes authors for a `Blog` from an array of `RemoteUser`s.
    /// - Parameters:
    ///   - blog: Blog object.
    ///   - remoteUsers: Array of `RemoteUser`s.
    @objc(updateBlogAuthorsForBlog:withRemoteUsers:inContext:)
    public func updateBlogAuthors(for blog: Blog, with remoteUsers: [RemoteUser], in context: NSManagedObjectContext) {
        do {
            guard let blog = try context.existingObject(with: blog.objectID) as? Blog else {
                return
            }

            remoteUsers.forEach {
                let blogAuthor = findBlogAuthor(with: $0.userID, and: blog, in: context)
                blogAuthor.userID = $0.userID
                blogAuthor.username = $0.username
                blogAuthor.email = $0.email
                blogAuthor.displayName = $0.displayName
                blogAuthor.primaryBlogID = $0.primaryBlogID
                blogAuthor.avatarURL = $0.avatarURL
                blogAuthor.linkedUserID = $0.linkedUserID
                blogAuthor.deletedFromBlog = false

                blog.addToAuthors(blogAuthor)
            }

            // Local authors who weren't included in the remote users array should be set as deleted.
            let remoteUserIDs = Set(remoteUsers.map { $0.userID })
            blog.authors?
                .filter { !remoteUserIDs.contains($0.userID) }
                .forEach { $0.deletedFromBlog = true }
        } catch {
            return
        }
    }

    static func blog(with site: JetpackSiteRef, context: NSManagedObjectContext = ContextManager.shared.mainContext) -> Blog? {
        let blog: Blog?

        if site.isSelfHostedWithoutJetpack, let xmlRPC = site.xmlRPC {
            blog = Blog.lookup(username: site.username, xmlrpc: xmlRPC, in: context)
        } else {
            blog = try? BlogQuery().blogID(site.siteID).dotComAccountUsername(site.username).blog(in: context)
        }

        return blog
    }
}

private extension BlogService {
    private func findBlogAuthor(with userId: NSNumber, and blog: Blog, in context: NSManagedObjectContext) -> BlogAuthor {
        return context.entity(of: BlogAuthor.self, with: NSPredicate(format: "\(#keyPath(BlogAuthor.userID)) = %@ AND \(#keyPath(BlogAuthor.blog)) = %@", userId, blog))
    }
}
