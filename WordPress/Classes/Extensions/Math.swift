extension Int {
    /**
     Rounds self to the nearest multiple of the given argument
     
     In case of a tie, it rounds to the multiple with the highest absolute value.
     That is, `-3.round(5)` rounds to `-5` and `3.round(5)` rounds to `5`
     
     - parameter divisor: a positive number that's a divisor of the result.
     - precondition: divisor must be > 0
     - returns: an Int rounded to the nearest integer that's a multiple of the argument.
     */
    func round(divisor: UInt) -> Int {
        assert(divisor > 0)
        if self == 0 || divisor == 0 {
            return self;
        }
        let sign = self / abs(self)
        let divisor = Int(divisor)
        let half = divisor / 2
        return self + sign * (half - (abs(self) + half) % divisor)
    }
}

extension Comparable {
    /**
     Clamps self between a minimum and maximum value
     
     - returns: the method returns
        - min if self < min
        - max if self > max
        - otherwise it returns self
     */
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
