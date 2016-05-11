import XCTest
import Nimble
@testable import WordPress

class MediaSettingsTests: XCTestCase {

    func testDefaultMaxImageSize() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        let maxImageSize = settings.maxImageSizeSetting
        expect(maxImageSize).to(equal(settings.allowedImageSizeRange.max))
    }

    func testMaxImageSizeMigratesCGSizeToInt() {
        let dimension = 1200
        let size = CGSize(width: dimension, height: dimension)
        let database = EphemeralKeyValueDatabase()
        database.setObject(NSStringFromCGSize(size), forKey: "SavedMaxImageSizeSetting")

        let settings = MediaSettings(database: database)
        expect(settings.maxImageSizeSetting).to(equal(dimension))
        let storedValue = database.objectForKey("SavedMaxImageSizeSetting") as? Int
        expect(storedValue).to(equal(dimension))
    }

    func testMaxImageSizeClampsValues() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        let lowValue = settings.allowedImageSizeRange.min - 1
        let highValue = settings.allowedImageSizeRange.max + 1

        settings.maxImageSizeSetting = lowValue
        expect(settings.maxImageSizeSetting).to(equal(settings.allowedImageSizeRange.min))
        settings.maxImageSizeSetting = highValue
        expect(settings.maxImageSizeSetting).to(equal(settings.allowedImageSizeRange.max))
    }

    func testImageSizeForUploadReturnsIntMax() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        let highValue = settings.allowedImageSizeRange.max + 1

        settings.maxImageSizeSetting = highValue
        expect(settings.imageSizeForUpload).to(equal(Int.max))

    }

}
