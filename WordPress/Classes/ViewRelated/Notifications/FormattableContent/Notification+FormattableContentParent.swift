
extension Notification: FormattableContentParent {
    var uniqueID: String? {
        return self.notificationId
    }

    func isEqual(to other: FormattableContentParent) -> Bool {
        guard let otherNotification = other as? Notification else {
            return false
        }
        return self == otherNotification
    }
}
