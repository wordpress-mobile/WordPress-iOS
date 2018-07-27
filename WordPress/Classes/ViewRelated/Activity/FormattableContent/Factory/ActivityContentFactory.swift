
struct ActivityContentFactory: FormattableContentFactory {

    public static func content(from blocks: [[String: AnyObject]],
                               actionsParser parser: FormattableContentActionParser) -> [FormattableContent] {

        return blocks.compactMap {
            let rawActions = getRawActions(from: $0)
            let actions = parser.parse(rawActions)
            let ranges = rangesFrom($0)
            let text = getText(from: $0)
            return FormattableTextContent(text: text, ranges: ranges, actions: actions)
        }
    }

    static func rangesFrom(_ dictionary: [String: AnyObject]) -> [FormattableContentRange] {
        let rawRanges = getRawRanges(from: dictionary)
        let parsed = rawRanges?.compactMap(ActivityRangesFactory.contentRange)
        return parsed ?? []
    }
}
