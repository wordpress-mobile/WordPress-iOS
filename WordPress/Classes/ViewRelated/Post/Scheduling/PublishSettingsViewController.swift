import Foundation
import WordPressData
import WordPressShared

struct PublishSettingsViewModel {
    enum State {
        case scheduled(Date)
        case published(Date)
        case immediately

        init(post: AbstractPost) {
            if let date = post.dateCreated {
                self = date > .now ? .scheduled(date) : .published(date)
            } else {
                self = .immediately
            }
        }
    }

    private(set) var state: State
    let timeZone: TimeZone

    private let post: AbstractPost

    var isRequired: Bool { post.original().isStatus(in: [.publish, .scheduled]) }

    init(post: AbstractPost) {
        state = State(post: post)

        self.post = post
        timeZone = post.blog.timeZone ?? TimeZone.current
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
        post.dateCreated = date
        state = State(post: post)
    }
}
