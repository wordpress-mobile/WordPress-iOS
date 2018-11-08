import Foundation

extension Double {

    func abbreviatedString() -> String {
        var num = self
        let sign = num < 0 ? "-" : ""
        num = fabs(num)

        if (num < 1000.0) {
            return "\(sign)\(Int(num))"
        }

        let exp: Int = Int(log10(num) / 3.0)
        let units: [String] = ["k", "M", "B", "T", "P", "E"]
        let roundedNum: Double = Foundation.round(10 * num / pow(1000.0, Double(exp))) / 10

        let remainder = roundedNum.truncatingRemainder(dividingBy: 1)
        if remainder > 0 {
            return "\(sign)\(roundedNum)\(units[exp-1])"
        } else {
            return "\(sign)\(Int(roundedNum))\(units[exp-1])"
        }
    }

}

extension NSNumber {
    func abbreviatedString() -> String {
        return self.doubleValue.abbreviatedString()
    }
}
