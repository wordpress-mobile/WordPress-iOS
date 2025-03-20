import Foundation

// MARK: - String NSRange and Location convertion Extensions
//
extension String {

    func compatibleSubstring(with range: Range<String.Index>) -> String {
        #if swift(>=4.0)
            return String(self[range])
        #else
            return self.substring(with: range)
        #endif
    }

    /// Converts a UTF16 NSRange into a Swift String NSRange for this string.
    ///
    /// - Parameters:
    ///     - nsRange: the UTF16 NSRange to convert.
    ///
    /// - Returns: the requested `Swift String NSRange`
    ///
    func nsRange(fromUTF16NSRange nsRange: NSRange) -> NSRange {

        let utf16Range = utf16.range(from: nsRange)
        let range = self.range(from: utf16Range)

        let location = distance(from: startIndex, to: range.lowerBound)
        let length = distance(from: range.lowerBound, to: range.upperBound)

        return NSRange(location: location, length: length)
    }

    /// Converts a Swift String NSRange into a UTF16 NSRange for this string.
    ///
    /// - Parameters:
    ///     - nsRange: the Swift String NSRange to convert.
    ///
    /// - Returns: the requested `UTF16 NSRange`
    ///
    func utf16NSRange(from nsRange: NSRange) -> NSRange {
        let swiftRange = range(from: nsRange)
        let utf16NSRange = self.utf16NSRange(from: swiftRange)

        return utf16NSRange
    }

    /// Converts an NSRange into a `Range<String.Index>` for this string.
    ///
    /// - Parameters:
    ///     - nsRange: the NSRange to convert.
    ///
    /// - Returns: the requested `Range<String.Index>`
    ///
    func range(from nsRange: NSRange) -> Range<String.Index> {
        let lowerBound = index(startIndex, offsetBy: nsRange.location)
        let upperBound = index(lowerBound, offsetBy: nsRange.length)

        return lowerBound ..< upperBound
    }

    func range(fromUTF16NSRange utf16NSRange: NSRange) -> Range<String.Index> {
        let swiftUTF16Range = utf16.range(from: utf16NSRange)
        return range(from: swiftUTF16Range)
    }

    /// Converts a `Range<String.UTF16View.Index>` into a `Range<String.Index>` for this string.
    ///
    /// - Parameters:
    ///     - nsRange: the UTF16 NSRange to convert.
    ///
    /// - Returns: the requested `Range<String.Index>`
    ///
    func range(from utf16Range: Range<String.UTF16View.Index>) -> Range<String.Index> {

        let start = self.findValidLowerBound(for: utf16Range)
        let end = self.findValidUpperBound(for: utf16Range)

        return start ..< end
    }

    /// Converts the lower bound of a `Range<String.UTF16View.Index>` into a valid `String.Index` for this string.
    /// Won't allow out-of-range errors.
    ///
    /// - Parameters:
    ///     - for: the UTF16 range to convert.
    ///
    /// - Returns: A valid lower bound represented as a `String.Index`
    ///
    private func findValidLowerBound(for utf16Range: Range<String.UTF16View.Index>) -> String.Index {

        guard isValidRange(utf16Range) else {
            return String.UTF16View.Index(utf16Offset: 0, in: self)
        }

        guard self.utf16.count >= utf16Range.lowerBound.utf16Offset(in: self) else {
            return String.UTF16View.Index(utf16Offset: 0, in: self)
        }

        return findValidBound(for: utf16Range.lowerBound, using: -)
    }

    /// Converts the upper bound of a `Range<String.UTF16View.Index>` into a valid `String.Index` for this string.
    /// Won't allow out-of-range errors.
    ///
    /// - Parameters:
    ///     - for: the UTF16 range to convert.
    ///
    /// - Returns: A valid upper bound represented as a `String.Index`
    ///
    private func findValidUpperBound(for utf16Range: Range<String.UTF16View.Index>) -> String.Index {

        guard isValidRange(utf16Range) else {
            return String.Index(utf16Offset: self.utf16.count, in: self)
        }

        guard self.utf16.count >= utf16Range.upperBound.utf16Offset(in: self) else {
            return String.Index(utf16Offset: self.utf16.count, in: self)
        }

        return findValidBound(for: utf16Range.upperBound, using: +)
    }

    /// Finds a valid UTF-8 `String.Index` matching the bound of a `String.UTF16View.Index`
    /// by adjusting the bound in a particular direction until it becomes valid.
    ///
    /// This is needed because some `String.UTF16View.Index` point to the middle of a UTF8
    /// grapheme cluster, which results in an invalid index, causing undefined behaviour.
    ///
    /// - Parameters:
    ///     - utf16Range: the UTF16View.Index to convert. Must be a valid index within the string.
    ///     - method: The method to use to move the bound – `+` or `-`
    ///
    /// - Returns: A corresponding `String.Index`
    ///
    private func findValidBound(for bound: String.UTF16View.Index, using method: (Int, Int) -> Int) -> String.Index {

        var newBound = bound.samePosition(in: self) // nil if we're inside a grapheme cluster
        var i = 1

        while newBound == nil {
            let newOffset = method(bound.utf16Offset(in: self), i)
            let newIndex = String.UTF16View.Index(utf16Offset: newOffset, in: self)
            newBound = newIndex.samePosition(in: self)
            i += 1
        }

        // We've verified aboe that this is a valid bound, so force upwrapping it is ok
        return newBound!
    }

    func nsRange(of string: String) -> NSRange? {
        guard let range = self.range(of: string) else {
            return nil
        }

        return nsRange(from: range)
    }

    /// Converts a `Range<String.Index>` into an UTF16 NSRange.
    ///
    /// - Parameters:
    ///     - range: the range to convert.
    ///
    /// - Returns: the requested `NSRange`.
    ///
    func nsRange(from range: Range<String.Index>) -> NSRange {

        let location = distance(from: startIndex, to: range.lowerBound)
        let length = distance(from: range.lowerBound, to: range.upperBound)

        return NSRange(location: location, length: length)
    }

    /// Converts a `Range<String.Index>` into an UTF16 NSRange.
    ///
    /// - Parameters:
    ///     - range: the range to convert.
    ///
    /// - Returns: the requested `NSRange`.
    ///
    func utf16NSRange(from range: Range<String.Index>) -> NSRange {

        guard let lowerBound = range.lowerBound.samePosition(in: utf16),
            let upperBound = range.upperBound.samePosition(in: utf16) else {
            fatalError()
        }

        let location = utf16.distance(from: utf16.startIndex, to: lowerBound)
        let length = utf16.distance(from: lowerBound, to: upperBound)

        return NSRange(location: location, length: length)
    }

    /// Returns a NSRange with a starting location at the very end of the string
    ///
    func endOfStringNSRange() -> NSRange {
        return NSRange(location: count, length: 0)
    }

    func indexFromLocation(_ location: Int) -> String.Index? {
        guard
            let unicodeLocation = utf16.index(utf16.startIndex, offsetBy: location, limitedBy: utf16.endIndex),
            let location = unicodeLocation.samePosition(in: self) else {
                return nil
        }

        return location
    }

    func isLastValidLocation(_ location: Int) -> Bool {
        if self.isEmpty {
            return false
        }
        return index(before: endIndex) == indexFromLocation(location)
    }

    func location(after: Int) -> Int? {
        guard let currentIndex = indexFromLocation(after), currentIndex != endIndex else {
            return nil
        }
        let afterIndex = index(after: currentIndex)
        guard let after16 = afterIndex.samePosition(in: utf16) else {
            return nil
        }

        return utf16.distance(from: utf16.startIndex, to: after16)
    }

    func location(before: Int) -> Int? {
        guard let currentIndex = indexFromLocation(before), currentIndex != startIndex else {
            return nil
        }

        let beforeIndex = index(before: currentIndex)
        guard let before16 = beforeIndex.samePosition(in: utf16) else {
            return nil
        }

        return utf16.distance(from: utf16.startIndex, to: before16)
    }

    func range(_ range: Range<String.Index>, offsetBy offset: Int) -> Range<String.Index> {

        let startIndex = index(range.lowerBound, offsetBy: offset)
        let endIndex = index(range.upperBound, offsetBy: offset)

        return startIndex ..< endIndex
    }

    func isValidRange(_ range: Range<String.UTF16View.Index>) -> Bool {
        isValidIndex(range.lowerBound) && isValidIndex(range.upperBound)
    }

    func isValidIndex(_ index: String.UTF16View.Index) -> Bool {
        (self.startIndex ..< self.endIndex).contains(index)
    }
}

private extension String.UTF16View {

    /// Converts a UTF16 `NSRange` into a `Range<String.UTF16View.Index>` for this string.
    ///
    /// - Parameters:
    ///     - nsRange: the UTF16 NSRange to convert.
    ///
    /// - Returns: the requested `Range<String.UTF16View.Index>` or `nil` if the conversion fails.
    ///
    func range(from nsRange: NSRange) -> Range<String.UTF16View.Index> {
        let start = index(startIndex, offsetBy: nsRange.location)
        let offset = count < nsRange.length ? count : nsRange.length

        guard nsRange.length > 0 else {
            return start ..< start
        }

        let end = index(start, offsetBy: offset)

        return start ..< end
    }
}
