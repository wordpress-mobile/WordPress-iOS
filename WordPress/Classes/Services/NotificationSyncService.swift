import Foundation


// MARK: NotificationSyncService
//
class NotificationSyncService
{
    /// GET /rest/v1.1/notifications/?http_envelope=1&fields=id%2Ctype%2Cunread%2Cbody%2Csubject%2Ctimestamp%2Cmeta%2Cnote_hash&number=10 HTTP/1.1
    ///
    func sync() {

    }

    /// https://developer.wordpress.com/docs/api/1.1/post/notifications/read/
    ///
    func markAsRead(noteID: String) {

    }

    /// https://developer.wordpress.com/docs/api/1.1/post/notifications/seen/
    ///
    func updateLastSeen(timestamp: String) {

    }
}
