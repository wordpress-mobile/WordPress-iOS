import Testing

@testable import WordPress

@Suite("CustomPostListDensity")
struct CustomPostListDensityTests {
    @Test("toggling flips between the two densities")
    func toggled() {
        #expect(CustomPostListDensity.comfortable.toggled == .condensed)
        #expect(CustomPostListDensity.condensed.toggled == .comfortable)
    }

    @Test("only condensed reports itself as condensed")
    func isCondensed() {
        #expect(CustomPostListDensity.condensed.isCondensed)
        #expect(!CustomPostListDensity.comfortable.isCondensed)
    }

    @Test("the toggle icon shows the density the tap switches to")
    func icon() {
        #expect(
            CustomPostListDensity.comfortable.toggleSystemImage != CustomPostListDensity.condensed.toggleSystemImage
        )
    }
}
