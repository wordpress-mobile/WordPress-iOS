
/// This class is used as part of the Notification Formattable Content system.
/// It inserts the given icon into an attributed string at the given range.
///
public class FormattableNoticonRange: FormattableContentRange {
    public var kind: FormattableRangeKind = .noticon
    public var range: NSRange
    public let value: String

    private var noticon: String {
        return value + " "
    }

    public init(value: String, range: NSRange) {
        self.value = value
        self.range = range
    }

    public func apply(_ styles: FormattableContentStyles, to string: NSMutableAttributedString, withShift shift: Int) -> FormattableContentRange.Shift {
        let shiftedRange = rangeShifted(by: shift)
        insertIcon(to: string, at: shiftedRange)

        let longerRange = NSMakeRange(shiftedRange.location, shiftedRange.length + noticon.count)
        apply(styles, to: string, at: longerRange)

        return noticon.count
    }

    func insertIcon(to string: NSMutableAttributedString, at shiftedRange: NSRange) {
        string.replaceCharacters(in: shiftedRange, with: noticon)
    }
}
