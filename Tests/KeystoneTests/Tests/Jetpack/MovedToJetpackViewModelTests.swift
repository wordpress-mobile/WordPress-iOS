import Testing

@testable import WordPress

struct MovedToJetpackViewModelTests {
    @Test(arguments: [MovedToJetpackSource.notifications, .stats])
    func descriptionDoesNotNameReaderInStaticScreensWithReader(source: MovedToJetpackSource) {
        let viewModel = MovedToJetpackViewModel(source: source, isReaderAvailable: true)

        #expect(!viewModel.description.contains(SharedStrings.Reader.title))
    }

    @Test(arguments: [MovedToJetpackSource.notifications, .stats, .reader])
    func descriptionNamesReaderOutsideStaticScreensWithReader(source: MovedToJetpackSource) {
        let viewModel = MovedToJetpackViewModel(source: source, isReaderAvailable: false)

        #expect(viewModel.description.contains(SharedStrings.Reader.title))
    }
}
