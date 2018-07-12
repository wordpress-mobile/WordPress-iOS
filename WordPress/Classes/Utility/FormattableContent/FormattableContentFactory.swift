
protocol FormattableContentFactory {
    static func content(from blocks: [[String: AnyObject]],
                        actionsParser parser: FormattableContentActionParser,
                        parent: FormattableContentParent) -> [FormattableContent]
}

struct ActivityFormattableContentFactory: FormattableContentFactory {
    public static func content(from blocks: [[String: AnyObject]],
                               actionsParser parser: FormattableContentActionParser,
                               parent: FormattableContentParent) -> [FormattableContent] {

        return blocks.compactMap {
            let actions = parser.parse($0[Constants.ActionsKey] as? [String: AnyObject])
            return FormattableTextContent(dictionary: $0, actions: actions, parent: parent)
        }
    }
}

private enum Constants {
    static let ActionsKey = "actions"
}
