// TODO: Delete when the reader improvements v1 (`readerImprovements`) flag is deleted
protocol ReaderSavedPostCellActionsDelegate: AnyObject {
    func willRemove(_ cell: OldReaderPostCardCell)
}
