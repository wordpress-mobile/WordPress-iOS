import Foundation

public struct StatsWordAdsEarningsResponse: Decodable {
    public let totalEarnings: Decimal
    public let totalAmountOwed: Decimal
    public let wordAdsEarnings: [MonthlyEarning]

    private enum CodingKeys: String, CodingKey {
        case earnings
    }

    private struct EarningsContainer: Decodable {
        let totalEarnings: FlexibleDecimal
        let totalAmountOwed: FlexibleDecimal
        let wordads: [String: MonthlyEarningData]

        private enum CodingKeys: String, CodingKey {
            case totalEarnings = "total_earnings"
            case totalAmountOwed = "total_amount_owed"
            case wordads
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let earningsContainer = try container.decode(EarningsContainer.self, forKey: .earnings)
        totalEarnings = earningsContainer.totalEarnings.value
        totalAmountOwed = earningsContainer.totalAmountOwed.value

        // Convert dictionary to sorted array
        var earnings = earningsContainer.wordads.compactMap { (period, data) -> MonthlyEarning? in
            guard let parsedPeriod = Period(string: period) else { return nil }
            return MonthlyEarning(period: parsedPeriod, data: data)
        }
        earnings.sort { $0.period > $1.period }
        wordAdsEarnings = earnings
    }

    public struct MonthlyEarning {
        public let period: Period
        public let amount: Decimal
        public let status: PaymentStatus
        public let pageviews: String

        public init(period: Period, data: MonthlyEarningData) {
            self.period = period
            self.amount = data.amount
            self.status = data.status
            self.pageviews = data.pageviews
        }
    }

    public struct MonthlyEarningData: Decodable {
        private let _amount: FlexibleDecimal
        private let _status: FlexiblePaymentStatus

        public let pageviews: String

        public var amount: Decimal { _amount.value }
        public var status: PaymentStatus { _status.value }

        public init(amount: Decimal, status: PaymentStatus, pageviews: String) {
            self._amount = FlexibleDecimal(value: amount)
            self._status = FlexiblePaymentStatus(value: status)
            self.pageviews = pageviews
        }

        private enum CodingKeys: String, CodingKey {
            case _amount = "amount"
            case _status = "status"
            case pageviews
        }
    }

    public enum PaymentStatus: Equatable {
        case paid
        case outstanding
    }

    public struct Period: Equatable, Comparable, Hashable {
        public let year: Int
        public let month: Int

        public init(year: Int, month: Int) {
            self.year = year
            self.month = month
        }

        init?(string: String) {
            let components = string.split(separator: "-")
            guard components.count == 2,
                  let year = Int(components[0]),
                  let month = Int(components[1]),
                  (1...12).contains(month) else {
                return nil
            }
            self.year = year
            self.month = month
        }

        public var string: String {
            String(format: "%04d-%02d", year, month)
        }

        public static func < (lhs: Period, rhs: Period) -> Bool {
            (lhs.year, lhs.month) < (rhs.year, rhs.month)
        }
    }
}

// MARK: - Decoding Helpers

private struct FlexibleDecimal: Decodable {
    let value: Decimal

    init(value: Decimal) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self), let decimal = Decimal(string: stringValue) {
            value = decimal
        } else if let doubleValue = try? container.decode(Double.self) {
            value = Decimal(doubleValue)
        } else if let intValue = try? container.decode(Int.self) {
            value = Decimal(intValue)
        } else {
            throw DecodingError.typeMismatch(Decimal.self, DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Expected string or number"
            ))
        }
    }
}

private struct FlexiblePaymentStatus: Decodable {
    let value: StatsWordAdsEarningsResponse.PaymentStatus

    init(value: StatsWordAdsEarningsResponse.PaymentStatus) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            value = stringValue == "1" ? .paid : .outstanding
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue == 1 ? .paid : .outstanding
        } else {
            throw DecodingError.typeMismatch(StatsWordAdsEarningsResponse.PaymentStatus.self, DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Expected string or int"
            ))
        }
    }
}
