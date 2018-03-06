import Foundation

/// This extension add methods to make the manipulation of disk quota values for a blog easier
extension Blog {

    /// Returns true if quota values are available for the site
    @objc var isQuotaAvailable: Bool {
        return quotaSpaceAllowed != nil && quotaSpaceUsed != nil
    }

    /// Returns the percentage value (0 to 1) of the disk space quota being used
    @objc var quotaPercentageUsed: NSNumber? {
        guard let quotaSpaceAllowed = quotaSpaceAllowed?.doubleValue, let quotaSpaceUsed = quotaSpaceUsed?.doubleValue else {
            return nil
        }
        let quotaPercentageUsed = quotaSpaceUsed / quotaSpaceAllowed
        return NSNumber(value: quotaPercentageUsed)
    }

    /// Returns the quota space allowed in a string format using human readable units (kb, Mb, Gb). EX: 1.5 Gb
    @objc var quotaSpaceAllowedDescription: String? {
        guard let quotaSpaceAllowed = quotaSpaceAllowed?.int64Value else {
            return nil
        }
        return ByteCountFormatter.string(fromByteCount: quotaSpaceAllowed, countStyle: .binary)
    }

    /// Returns the disk quota percentage in a human readable format. Ex: 5%
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
