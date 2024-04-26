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

    /// Returns an human readable message indicating the percentage of disk quota space available in regard to the maximum allowed.Ex: 10% of 15 GB used
    @objc var quotaUsageDescription: String? {
        guard isQuotaAvailable, let quotaPercentageUsedDescription = self.quotaPercentageUsedDescription, let quotaSpaceAllowedDescription = self.quotaSpaceAllowedDescription else {
            return nil
        }
        let formatString = NSLocalizedString("%@ of %@ used on your site", comment: "Amount of disk quota being used. First argument is the total percentage being used second argument is total quota allowed in GB.Ex: 33% of 14 GB used on your site.")
        return String(format: formatString, quotaPercentageUsedDescription, quotaSpaceAllowedDescription)
    }

    /// Returns the disk space quota still available to use in the site.
    @objc var quotaSpaceAvailable: NSNumber? {
        guard let quotaSpaceAllowed = quotaSpaceAllowed?.int64Value, let quotaSpaceUsed = quotaSpaceUsed?.int64Value else {
            return nil
        }
        let quotaSpaceAvailable = quotaSpaceAllowed - quotaSpaceUsed
        return NSNumber(value: quotaSpaceAvailable)
    }

    /// Returns the maximum upload byte size supported for a media file on the site.
    @objc var maxUploadSize: NSNumber? {
        guard let maxUploadSize = getOptionValue("max_upload_size") as? NSNumber else {
            return nil
        }
        return maxUploadSize
    }

    /// Returns true if the site has disk quota available to for the file size of the URL provided.
    ///
    /// If no quota information is available for the site this method returns true.
    /// - Parameter url: the file URL to check the filesize
    /// - Returns: true if there is space available
    @objc func hasSpaceAvailable(for url: URL) -> Bool {
        guard let fileSize = url.fileSize,
              let spaceAvailable = quotaSpaceAvailable?.int64Value
        else {
            // let's assume the site can handle it if we don't know any of quota or fileSize information.
            return true
        }
        return fileSize < spaceAvailable
    }

    /// Returns true if the site is able to support the file size of an upload made with the specified URL.
    ///
    /// - Parameter url: the file URL to check the filesize.
    /// - Returns: true if the site is able to support the URL file size.
    @objc func isAbleToHandleFileSizeOf(url: URL) -> Bool {
        guard let fileSize = url.fileSize,
            let maxUploadSize = maxUploadSize?.int64Value,
            maxUploadSize > 0
            else {
                // let's assume the site can handle it.
                return true
        }
        return fileSize < maxUploadSize
    }
}
