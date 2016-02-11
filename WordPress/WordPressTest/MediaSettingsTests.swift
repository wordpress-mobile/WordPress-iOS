import XCTest
import Nimble
@testable import WordPress

class MediaSettingsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDefaultMaxImageSize() {
        let settings = MediaSettings(storage: MediaSettings.EphemeralStorage())
        let maxImageSize = settings.maxImageSizeSetting
        expect(maxImageSize).to(equal(settings.maxImageDimension))
    }

    func testMaxImageSizeMigratesCGSizeToInt() {
        let dimension = 1200
        let size = CGSize(width: dimension, height: dimension)
        let storage = MediaSettings.EphemeralStorage()
        storage.setValue(NSStringFromCGSize(size), forKey: "SavedMaxImageSizeSetting")

        let settings = MediaSettings(storage: storage)
        expect(settings.maxImageSizeSetting).to(equal(dimension))
        let storedValue = storage.valueForKey("SavedMaxImageSizeSetting") as? Int
        expect(storedValue).to(equal(dimension))
    }

    func testMaxImageSizeClampsValues() {
        let settings = MediaSettings(storage: MediaSettings.EphemeralStorage())
        let lowValue = settings.minImageDimension - 1
        let highValue = settings.maxImageDimension + 1

        settings.maxImageSizeSetting = lowValue
        expect(settings.maxImageSizeSetting).to(equal(settings.minImageDimension))
        settings.maxImageSizeSetting = highValue
        expect(settings.maxImageSizeSetting).to(equal(settings.maxImageDimension))
    }

    func testImageSizeForUploadReturnsIntMax() {
        let settings = MediaSettings(storage: MediaSettings.EphemeralStorage())
        let highValue = settings.maxImageDimension + 1

        settings.maxImageSizeSetting = highValue
        expect(settings.imageSizeForUpload).to(equal(Int.max))

    }

}
