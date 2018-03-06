import Foundation

/// This extension add methods to make the manipulation of disk quota values for a blog easier
extension Blog {

    @objc var isQuotaAvailable: Bool {
        return quotaSpaceAllowed != nil && quotaSpaceUsed != nil
    }

    @objc var quotaPercentageUsed: NSNumber? {
        guard let quotaSpaceAllowed = quotaSpaceAllowed?.int64Value, let quotaSpaceUsed = quotaSpaceUsed?.int64Value else {
            return nil
        }
        let quotaPercentageUsed = Double(quotaSpaceUsed) / Double(quotaSpaceAllowed)
        return NSNumber(value: quotaPercentageUsed)
    }

    @objc var quotaSpaceAllowedDescription: String? {
        guard let quotaSpaceAllowed = quotaSpaceAllowed?.int64Value else {
            return nil
        }
        return ByteCountFormatter.string(fromByteCount: quotaSpaceAllowed, countStyle: .binary)
    }

    @objc var quotaPercentageUsedDescription: String? {
        let percentageFormatter = NumberFormatter()
        percentageFormatter.numberStyle = .percent
        guard let percentage = quotaPercentageUsed,
              let quotaPercentageUsedDescription = percentageFormatter.string(from: percentage) else {
            return nil
        }
        return quotaPercentageUsedDescription
    }
}
