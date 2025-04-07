import Foundation
import CoreData
import WordPressKit

public class BloggingPromptSettings: NSManagedObject {

    public static func of(_ blog: Blog) throws -> BloggingPromptSettings? {
        guard let context = blog.managedObjectContext else { return nil }

        // This getting site id logic is copied from the BloggingPromptsService initializer.
        let siteID: NSNumber
        if let id = blog.dotComID {
            siteID = id
        } else if let account = try WPAccount.lookupDefaultWordPressComAccount(in: context), let primaryBlogID = account.primaryBlogID {
            siteID = primaryBlogID
        } else {
            return nil
        }

        return try lookup(withSiteID: siteID, in: context)
    }

    public static func lookup(withSiteID siteID: NSNumber, in context: NSManagedObjectContext) throws -> BloggingPromptSettings? {
        let fetchRequest = BloggingPromptSettings.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "\(#keyPath(BloggingPromptSettings.siteID)) = %@", siteID)
        fetchRequest.fetchLimit = 1
        return try context.fetch(fetchRequest).first
    }

    public func reminderTimeDate() -> Date? {
        guard let reminderTime else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH.mm"
        return dateFormatter.date(from: reminderTime)
    }
}

public extension RemoteBloggingPromptsSettings {

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
