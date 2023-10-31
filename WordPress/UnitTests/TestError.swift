/// Global free function only available for the unit test target to make creating general purpose errors in the test DRY and self-documenting.
///
/// The Swift API guidelines reccomend against free functions, but the improved ergonomics and limited scope make the approach worth the trade off in this case.
func testError(id: Int = 1, description: String = "A test error") -> Error {
    NSError.testInstance(description: description, code: id)
}
