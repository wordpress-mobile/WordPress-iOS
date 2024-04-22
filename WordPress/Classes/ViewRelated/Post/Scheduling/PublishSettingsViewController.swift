import Foundation
import CocoaLumberjack
import WordPressShared
import WordPressFlux

struct PublishSettingsViewModel {
    enum State {
        case scheduled(Date)
        case published(Date)
        case immediately

        init(post: AbstractPost) {
            if RemoteFeatureFlag.syncPublishing.enabled() {
                if let date = post.dateCreated {
                    self = date > .now ? .scheduled(date) : .published(date)
                } else {
                    self = .immediately
                }
            } else {
                if let dateCreated = post.dateCreated, post.shouldPublishImmediately() == false {
                    self = post.hasFuturePublishDate() ? .scheduled(dateCreated) : .published(dateCreated)
                } else {
                    self = .immediately
                }
            }
        }
    }

    private(set) var state: State
    let timeZone: TimeZone
    let title: String?

    var detailString: String {
        guard RemoteFeatureFlag.syncPublishing.enabled() else {
            return _detailString
        }
        switch state {
        case .scheduled(let date), .published(let date):
            return dateTimeFormatter.string(from: date)
        case .immediately:
            return NSLocalizedString("Immediately", comment: "Undated post time label")
        }
    }

    /// - note: deprecated (kahu-offline-mode)
    var _detailString: String {
        if let date = date, !post.shouldPublishImmediately() {
            return dateTimeFormatter.string(from: date)
        } else {
            return NSLocalizedString("Immediately", comment: "Undated post time label")
        }
    }

    private let post: AbstractPost

    var isRequired: Bool { (post.original ?? post).status == .publish }
    let dateFormatter: DateFormatter
    let dateTimeFormatter: DateFormatter

    init(post: AbstractPost, context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {
        state = State(post: post)

        self.post = post

        title = post.postTitle
        timeZone = post.blog.timeZone ?? TimeZone.current

        dateFormatter = SiteDateFormatters.dateFormatter(for: timeZone, dateStyle: .long, timeStyle: .none)
        dateTimeFormatter = SiteDateFormatters.dateFormatter(for: timeZone, dateStyle: .medium, timeStyle: .short)
    }

    var date: Date? {
        switch state {
        case .scheduled(let date), .published(let date):
            return date
        case .immediately:
            return nil
        }
    }

    mutating func setDate(_ date: Date?) {
        guard RemoteFeatureFlag.syncPublishing.enabled() else {
            return _setDate(date)
        }
        post.dateCreated = date
        state = State(post: post)
    }

    /// - note: deprecated (kahu-offline-mode)
    mutating func _setDate(_ date: Date?) {
        if let date = date {
            // If a date to schedule the post was given
            post.dateCreated = date
            if post.shouldPublishImmediately() {
                post.status = .publish
            } else {
                post.status = .scheduled
            }
        } else if post.originalIsDraft() {
            // If the original is a draft, keep the post as a draft
            post.status = .draft
            post.publishImmediately()
        } else if post.hasFuturePublishDate() {
            // If the original is a already scheduled post, change it to publish immediately
            // In this case the user had scheduled, but now wants to publish right away
            post.publishImmediately()
        }

        state = State(post: post)
    }
}
