import WordPressShared
import XCTest
@testable import WordPress

class MediaSettingsTests: XCTestCase {

    // MARK: - Default values
    func testDefaultMaxImageSize() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        let maxImageSize = settings.maxImageSizeSetting
        XCTAssertEqual(maxImageSize, 2000)
    }

    func testDefaultImageOptimization() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        let imageOptimization = settings.imageOptimizationEnabled
        XCTAssertTrue(imageOptimization)
    }

    func testDefaultImageQuality() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        let imageQuality = settings.imageQualitySetting
        XCTAssertEqual(imageQuality, .medium)
    }

    // MARK: - Max Image Size values
    func testMaxImageSizeMigratesCGSizeToInt() {
        let dimension = Int(1200)
        let size = CGSize(width: dimension, height: dimension)
        let database = EphemeralKeyValueDatabase()
        database.set(NSCoder.string(for: size), forKey: "SavedMaxImageSizeSetting")

        let settings = MediaSettings(database: database)
        XCTAssertEqual(settings.maxImageSizeSetting, dimension)
    }

    func testMaxImageSizeClampsValues() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        let lowValue = settings.allowedImageSizeRange.min - 1
        let highValue = settings.allowedImageSizeRange.max + 1

        settings.maxImageSizeSetting = lowValue
        XCTAssertEqual(settings.maxImageSizeSetting, settings.allowedImageSizeRange.min)
        settings.maxImageSizeSetting = highValue
        XCTAssertEqual(settings.maxImageSizeSetting, settings.allowedImageSizeRange.max)
    }

    func testImageSizeForUploadReturnsIntMax() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        let highValue = settings.allowedImageSizeRange.max + 1

        settings.maxImageSizeSetting = highValue
        XCTAssertEqual(settings.imageSizeForUpload, Int.max)

    }

    // MARK: - Values based on image optimization
    func testImageSizeForUploadValueBasedOnOptimization() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        XCTAssertEqual(settings.imageSizeForUpload, 2000)
        settings.imageOptimizationEnabled = false
        XCTAssertEqual(settings.imageSizeForUpload, Int.max)
    }

    func testImageQualityForUploadValueBasedOnOptimization() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        XCTAssertEqual(settings.imageQualityForUpload, .medium)
        settings.imageOptimizationEnabled = false
        XCTAssertEqual(settings.imageQualityForUpload, .high)
    }
}
