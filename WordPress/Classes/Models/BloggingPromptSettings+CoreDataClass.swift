import Foundation
import CoreData
import WordPressKit

public class BloggingPromptSettings: NSManagedObject {

    static func of(_ blog: Blog) throws -> BloggingPromptSettings? {
        guard let context = blog.managedObjectContext else { return nil }

        // This getting site id logic is copied from the BloggingPromptsService initializer.
        let siteID: NSNumber
        if let id = blog.dotComID {
            siteID = id
        } else if let account = try WPAccount.lookupDefaultWordPressComAccount(in: context) {
            siteID = account.primaryBlogID
        } else {
            return nil
        }

        return try lookup(withSiteID: siteID, in: context)
    }

    static func lookup(withSiteID siteID: NSNumber, in context: NSManagedObjectContext) throws -> BloggingPromptSettings? {
        let fetchRequest = BloggingPromptSettings.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "\(#keyPath(BloggingPromptSettings.siteID)) = %@", siteID)
        fetchRequest.fetchLimit = 1
        return try context.fetch(fetchRequest).first
    }

    func configure(with remoteSettings: RemoteBloggingPromptsSettings, siteID: Int32, context: NSManagedObjectContext) {
        self.siteID = siteID
        self.promptCardEnabled = remoteSettings.promptCardEnabled
        self.reminderTime = remoteSettings.reminderTime
        self.promptRemindersEnabled = remoteSettings.promptRemindersEnabled
        self.isPotentialBloggingSite = remoteSettings.isPotentialBloggingSite
        updatePromptSettingsIfNecessary(siteID: Int(siteID), enabled: isPotentialBloggingSite)
        self.reminderDays = reminderDays ?? BloggingPromptSettingsReminderDays(context: context)
        reminderDays?.configure(with: remoteSettings.reminderDays)
    }

    func reminderTimeDate() -> Date? {
        guard let reminderTime = reminderTime else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH.mm"
        return dateFormatter.date(from: reminderTime)
    }

    private func updatePromptSettingsIfNecessary(siteID: Int, enabled: Bool) {
        DispatchQueue.main.async {
            let service = BlogDashboardPersonalizationService(siteID: siteID)
            if !service.hasPreference(for: .prompts) {
                service.setEnabled(enabled, for: .prompts)
            }
        }
    }
}

extension RemoteBloggingPromptsSettings {

    init(with model: BloggingPromptSettings) {
        self.init(promptCardEnabled: model.promptCardEnabled,
                  promptRemindersEnabled: model.promptRemindersEnabled,
                  reminderDays: ReminderDays(monday: model.reminderDays?.monday ?? false,
                                             tuesday: model.reminderDays?.tuesday ?? false,
                                             wednesday: model.reminderDays?.wednesday ?? false,
                                             thursday: model.reminderDays?.thursday ?? false,
                                             friday: model.reminderDays?.friday ?? false,
                                             saturday: model.reminderDays?.saturday ?? false,
                                             sunday: model.reminderDays?.sunday ?? false),
                  reminderTime: model.reminderTime ?? String(),
                  isPotentialBloggingSite: model.isPotentialBloggingSite)
    }

}
