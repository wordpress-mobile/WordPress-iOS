
struct ActivityContentFactory: FormattableContentFactory {
    public static func content(from blocks: [[String: AnyObject]],
                               actionsParser parser: FormattableContentActionParser,
                               parent: FormattableContentParent) -> [FormattableContent] {

        return blocks.compactMap {
            let rawActions = getRawActions(from: $0)
            let actions = parser.parse(rawActions)
            let ranges = rangesFrom($0)
            print("rawActions ", rawActions)
            print("ranges ", ranges)
            return FormattableTextContent(dictionary: $0, actions: actions, ranges: ranges, parent: parent)
        }
    }

    static func rangesFrom(_ dictionary: [String: AnyObject]) -> [FormattableContentRange] {
        let rawRanges = getRawRanges(from: dictionary)
        let parsed = rawRanges?.compactMap(ActivityRangesFactory.contentRange)
        return parsed ?? []
    }
}
