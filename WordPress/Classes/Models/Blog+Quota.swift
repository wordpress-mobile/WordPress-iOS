import Foundation

extension Blog {

    @objc var isQuotaAvailable: Bool {
        return quotaSpaceAllowed != nil && quotaSpaceUsed != nil
    }

    @objc var quotaPercentangeUsed: NSNumber? {
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
        return ByteCountFormatter.string(fromByteCount: quotaSpaceAllowed, countStyle: ByteCountFormatter.CountStyle.file)
    }

    @objc var quotaPercentageUsedDescription: String? {
        let percentageFormatter = NumberFormatter()
        percentageFormatter.numberStyle = .percent
        guard let percentage = quotaPercentangeUsed,
              let quotaPercentageUsedDescription = percentageFormatter.string(from: percentage) else {
            return nil
        }
        return quotaPercentageUsedDescription
    }
}
