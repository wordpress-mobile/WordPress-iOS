
protocol FormattableContentFactory {

}

extension FormattableContentFactory {
    static func getRawActions(from dictionary: [String: AnyObject]) -> [String: AnyObject]? {
        return dictionary[Constants.ActionsKey] as? [String: AnyObject]
    }

    static func getRawRanges(from dictionary: [String: AnyObject]) -> [[String: AnyObject]]? {
        return dictionary[Constants.Ranges] as? [[String: AnyObject]]
    }

    static func getText(from dictionary: [String: AnyObject]) -> String {
        return dictionary[Constants.Text] as? String ?? ""
    }
}

private enum Constants {
    static let ActionsKey = "actions"
    static let Ranges = "ranges"
    static let Text = "text"
}
