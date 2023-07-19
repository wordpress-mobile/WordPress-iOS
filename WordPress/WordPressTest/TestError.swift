struct TestError: Error {

    let id: Int

    init(id: Int = 1) {
        self.id = id
    }
}
