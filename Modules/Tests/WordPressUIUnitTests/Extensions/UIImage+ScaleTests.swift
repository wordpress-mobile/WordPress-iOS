import Testing
import WordPressUI

struct UIImageScaleTests {

    let originalImage = UIImage(color: .blue, size: CGSize(width: 1024, height: 768))

    @Test func aspectFitIntoSquare() {
        let targetSize = CGSize(width: 1000, height: 1000)
        let size = originalImage.dimensions(forSuggestedSize: targetSize, format: .scaleAspectFit)
        #expect(size == CGSize(width: 1000, height: 750))
    }

    @Test func aspectFitIntoSmallerSize() {
        let targetSize = CGSize(width: 101, height: 76)
        let size = originalImage.dimensions(forSuggestedSize: targetSize, format: .scaleAspectFit)
        #expect(size == targetSize)
    }

    @Test func aspectFitIntoLargerSize() {
        let targetSize = CGSize(width: 2000, height: 1000)
        let size = originalImage.dimensions(forSuggestedSize: targetSize, format: .scaleAspectFit)
        #expect(size == CGSize(width: 1333, height: 1000))
    }

    @Test func aspectFillIntoSquare() {
        let targetSize = CGSize(width: 100, height: 100)
        let size = originalImage.dimensions(forSuggestedSize: targetSize, format: .scaleAspectFill)
        #expect(size == CGSize(width: 133, height: 100))
    }

    @Test func aspectFillIntoSmallerSize() {
        let targetSize = CGSize(width: 103, height: 77)
        let size = originalImage.dimensions(forSuggestedSize: targetSize, format: .scaleAspectFill)
        #expect(size == targetSize)
    }

    @Test func aspectFillIntoLargerSize() {
        let targetSize = CGSize(width: 2000, height: 1000)
        let size = originalImage.dimensions(forSuggestedSize: targetSize, format: .scaleAspectFill)
        #expect(size == CGSize(width: 2000, height: 1500))
    }

    @Test func zeroTargetSize() {
        let targetSize = CGSize(width: 0, height: 0)
        let originalImage = UIImage(color: .blue, size: CGSize(width: 1024, height: 680))
        let size = originalImage.dimensions(forSuggestedSize: targetSize, format: .scaleAspectFill)
        #expect(size == CGSize(width: 0, height: 0))
    }
}
