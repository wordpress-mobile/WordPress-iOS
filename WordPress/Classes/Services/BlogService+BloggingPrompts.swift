import CoreData

extension BlogService {

    @objc func updatePromptSettings(for blog: RemoteBlog?, context: NSManagedObjectContext) {
        guard let blog = blog,
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

}
