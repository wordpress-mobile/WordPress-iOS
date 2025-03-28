import Foundation
import CocoaLumberjackSwift
import CoreData
import WordPressKit
import WordPressShared
import FormattableContentKit

// MARK: - Notification Entity
//
@objc(Notification)
public class Notification: NSManagedObject {
    /// Notification Primary Key!
    ///
    @NSManaged public var notificationId: String

    /// Notification Hash!
    ///
    @NSManaged public var notificationHash: String?

    /// Indicates whether the note was already read, or not
    ///
    @NSManaged public var read: Bool

    /// Associated Resource's Icon, as a plain string
    ///
    @NSManaged public var icon: String?

    /// Noticon resource, associated with this notification
    ///
    @NSManaged public var noticon: String?

    /// Timestamp as a String
    ///
    @NSManaged public var timestamp: String?

    /// Notification Type
    ///
    @NSManaged public var type: String?

    /// Associated Resource's URL
    ///
    @NSManaged public var url: String?

    /// Plain Title ("1 Like" / Etc)
    ///
    @NSManaged public var title: String?

    /// Raw Subject Blocks
    ///
    @NSManaged public var subject: [AnyObject]?

    /// Raw Header Blocks
    ///
    @NSManaged public var header: [AnyObject]?

    /// Raw Body Blocks
    ///
    @NSManaged public var body: [AnyObject]?

    /// Raw Associated Metadata
    ///
    @NSManaged public var meta: [String: AnyObject]?

    /// Timestamp As Date Transient Storage.
    ///
    public private(set) var cachedTimestampAsDate: Date?

    public let formatter = FormattableContentFormatter()

    /// Subject Blocks Transient Storage.
    ///
    public var cachedSubjectContentGroup: FormattableContentGroup?

    /// Header Blocks Transient Storage.
    ///
    public var cachedHeaderContentGroup: FormattableContentGroup?

    /// Body Blocks Transient Storage.
    ///
    public var cachedBodyContentGroups: [FormattableContentGroup]?

    /// Header + Body Blocks Transient Storage.
    ///
    public var cachedHeaderAndBodyContentGroups: [FormattableContentGroup]?

    private var cachedAttributesObserver: NotificationCachedAttributesObserver?

    /// Array that contains the Cached Property Names
    ///
    fileprivate static let cachedAttributes = Set(arrayLiteral: "body", "header", "subject", "timestamp")

    public override func awakeFromFetch() {
        super.awakeFromFetch()

        if cachedAttributesObserver == nil {
            let observer = NotificationCachedAttributesObserver()
            for attr in Notification.cachedAttributes {
                addObserver(observer, forKeyPath: attr, options: [.prior], context: nil)
            }
            cachedAttributesObserver = observer
        }
    }

    deinit {
        if let observer = cachedAttributesObserver {
            for attr in Notification.cachedAttributes {
                removeObserver(observer, forKeyPath: attr)
            }
        }
    }

    /// Nukes any cached values.
    ///
    public func resetCachedAttributes() {
        cachedTimestampAsDate = nil

        formatter.resetCache()
        cachedBodyContentGroups = nil
        cachedHeaderContentGroup = nil
        cachedSubjectContentGroup = nil
        cachedHeaderAndBodyContentGroups = nil
    }

    // This is a NO-OP that will force NSFetchedResultsController to reload the row for this object.
    // Helpful when dealing with transient attributes.
    //
    @objc func didChangeOverrides() {
        let readValue = read
        read = readValue
    }

    /// Parse the Timestamp as a Cocoa Date Instance.
    ///
    @objc public var timestampAsDate: Date {
        assert(timestamp != nil, "Notification Timestamp should not be nil [\(notificationId)]")

        if let timestampAsDate = cachedTimestampAsDate {
            return timestampAsDate
        }

        guard let timestamp, let timestampAsDate = Date.dateWithISO8601String(timestamp) else {
            DDLogError("Error: couldn't parse date [\(String(describing: self.timestamp))] for notification with id [\(notificationId)]")
            return Date()
        }

        cachedTimestampAsDate = timestampAsDate
        return timestampAsDate
    }
}

private class NotificationCachedAttributesObserver: NSObject {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath, let notification = object as? Notification, Notification.cachedAttributes.contains(keyPath) else {
            return
        }

        guard (change?[.notificationIsPriorKey] as? NSNumber)?.boolValue == true else {
            return
        }

        // Note:
        // Cached Attributes are only consumed on the main thread, when initializing UI elements.
        // As an optimization, we'll only reset those attributes when we're running on the main thread.
        //
        guard notification.managedObjectContext?.concurrencyType == .mainQueueConcurrencyType else {
            return
        }

        notification.resetCachedAttributes()
    }
}
