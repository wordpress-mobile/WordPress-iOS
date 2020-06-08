extension Comparable {
    /// Clamps self between a minimum and maximum value
    ///
    /// - Returns: the method returns
    ///     - min if self < min
    ///     - max if self > max
    ///     - otherwise it returns self
    ///
    func clamp(min minValue: Self, max maxValue: Self) -> Self {
        return Swift.min(Swift.max(self, minValue), maxValue)
    }
}

extension CGSize {
    func clamp(min minValue: CGSize, max maxValue: CGSize) -> CGSize {
        let width = self.width.clamp(min: minValue.width, max: maxValue.width)
        let height = self.height.clamp(min: minValue.height, max: maxValue.height)
        return CGSize(width: width, height: height)
    }

    func clamp(min minValue: CGFloat, max maxValue: CGFloat) -> CGSize {
        let minSize = CGSize(width: minValue, height: minValue)
        let maxSize = CGSize(width: maxValue, height: maxValue)
        return clamp(min: minSize, max: maxSize)
    }

    func clamp(min minValue: Int, max maxValue: Int) -> CGSize {
        return clamp(min: CGFloat(minValue), max: CGFloat(maxValue))
    }
}

extension CGFloat {
    func zeroIfNaN() -> CGFloat {
        return self.isNaN ? 0.0 : self
    }
}
