import XCTest
import WordPressUI

final class UIImage_CropTests: XCTestCase {

    func testSquared() throws {
        let image = try XCTUnwrap(createImage(size: .init(width: 96.0, height: 96.1)))
        let squareImage = image.squared()
        XCTAssertEqual(squareImage.size.width, squareImage.size.height)
    }

    private func createImage(color: UIColor = .blue, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRectMake(0, 0, size.width, size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
