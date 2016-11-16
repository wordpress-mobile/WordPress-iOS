import Foundation
import WordPressComAnalytics

/// Helper methods for Reader Topics
extension ReaderAbstractTopic {

    /// Returns true if the topic is a default topic
    public var isDefault: Bool {
        return self is ReaderDefaultTopic
    }

    /// Returns true if the topic is a list topic
    public var isList: Bool {
        return self is ReaderListTopic
    }

    /// Returns true if the topic is a site topic
    public var isSite: Bool {
        return self is ReaderSiteTopic
    }

    /// Returns true if the topic is a tag topic
    public var isTag: Bool {
        return self is ReaderTagTopic
    }

    /// Returns true if the topic is a search topic
    public var isSearch: Bool {
        return self is ReaderSearchTopic
    }

    /// Returns true if the topic is a freshly pressed topic
    public var isFreshlyPressed: Bool {
        return self.path.hasSuffix("/freshly-pressed")
    }


    /// Returns true if the topic is a discover topic
    public var isDiscover: Bool {
        return self.path.containsString("/read/sites/53424024/posts")
    }


    /// Returns true if the topic is a following topic
    public var isFollowing: Bool {
        return self.path.hasSuffix("/read/following")
    }


    /// Returns true if the topic is a liked topic
    public var isLiked: Bool {
        return self.path.hasSuffix("/read/liked")
    }

    /// Returns true if the topic is a team topic
    public var isTeam: Bool {
        return self is ReaderTeamTopic
    }

    // MARK: Analytics Helpers

    public func trackLoaded(withProperties properties:[NSObject : AnyObject]) {
        var stat:WPAnalyticsStat?

        if isFreshlyPressed {
            stat = .ReaderFreshlyPressedLoaded

        } else if isDefault && isDiscover {
            // Tracks Discover only if it was one of the default menu items.
            stat = .ReaderDiscoverViewed

        } else if isList {
            stat = .ReaderListLoaded

        } else if isTag {
            stat = .ReaderTagLoaded
        }

        if (stat != nil) {
            WPAnalytics.track(stat!, withProperties: properties)
        }
    }
}
