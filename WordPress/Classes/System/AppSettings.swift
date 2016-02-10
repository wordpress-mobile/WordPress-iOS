import Foundation

class AppSettings: NSObject {
    private static let maxImageSizeKey = "SavedMaxImageSizeSetting"
    
    static let minImageDimension = 150
    static let maxImageDimension = 3000

    /// The absolute maximum size that the app can use as a setting. If `maxImageSizeSetting` matches this value, images won't be resized.
    private static var absoluteMaxImageSize: CGSize {
        return CGSize(width: maxImageDimension, height: maxImageDimension)
    }

    static var maxImageSizeSetting: CGSize {
        get {
            if let savedSize = NSUserDefaults.standardUserDefaults().stringForKey(maxImageSizeKey) {
                return CGSizeFromString(savedSize)
            } else {
                return absoluteMaxImageSize
            }
        }
        set {
            let size = newValue.clamp(min: minImageDimension, max: maxImageDimension)
            let sizeString = NSStringFromCGSize(size)
            NSUserDefaults.standardUserDefaults().setObject(sizeString, forKey: maxImageSizeKey)
            NSUserDefaults.resetStandardUserDefaults()
        }
    }

    /// The size that an image needs to be resized to before uploading, or CGSizeZero if it shouldn't be resized.
    static var imageSizeForUpload: CGSize {
        if maxImageSizeSetting == absoluteMaxImageSize {
            return CGSizeZero
        } else {
            return maxImageSizeSetting
        }
    }
}
