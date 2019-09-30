@testable import WordPress

class FileDownloadsStatsRecordValueTests: StatsTestCase {

    func testCreation() {
        let parent = createStatsRecord(in: mainContext, type: .fileDownloads, period: .month, date: Date())

        let fileDownload = FileDownloadsStatsRecordValue(parent: parent)
        fileDownload.file = "test.ext"
        fileDownload.downloadCount = 9001

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .fileDownloads, on: Date(), periodType: .month)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 1)

        let fetchedDownloads = results.first?.values?.firstObject! as! FileDownloadsStatsRecordValue

        XCTAssertEqual(fetchedDownloads.file, fileDownload.file)
        XCTAssertEqual(fetchedDownloads.downloadCount, fileDownload.downloadCount)
    }
}
