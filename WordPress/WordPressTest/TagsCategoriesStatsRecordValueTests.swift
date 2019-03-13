@testable import WordPress
@testable import WordPressKit

class TagsCategoriesStatsRecordValueTests: StatsTestCase {


    func testCreation() {
        let parent = createStatsRecord(in: mainContext, type: .tagsAndCategories, date: Date())

        let tag = TagsCategoriesStatsRecordValue(parent: parent)
        tag.name = "test"
        tag.type = TagsCategoriesType.tag.rawValue

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .tagsAndCategories)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 1)

        let fetchedTag = results.first?.values?.firstObject! as! TagsCategoriesStatsRecordValue

        XCTAssertEqual(fetchedTag.name, tag.name)
        XCTAssertEqual(fetchedTag.type, tag.type)
    }

    func testChildrenRelationships() {
        let parent = createStatsRecord(in: mainContext, type: .tagsAndCategories, date: Date())

        let folder = TagsCategoriesStatsRecordValue(parent: parent)
        folder.name = "test"
        folder.type = TagsCategoriesType.folder.rawValue

        let tag = TagsCategoriesStatsRecordValue(context: mainContext)
        tag.name = "test"
        tag.type = TagsCategoriesType.tag.rawValue

        let category = TagsCategoriesStatsRecordValue(context: mainContext)
        category.name = "Category"
        category.type = TagsCategoriesType.category.rawValue

        folder.addToChildren([tag, category])

        let fr = StatsRecord.fetchRequest(for: .tagsAndCategories)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 1)

        let fetchedCategory = results.first?.values?.firstObject! as! TagsCategoriesStatsRecordValue
        let children = fetchedCategory.children?.array as? [TagsCategoriesStatsRecordValue]

        XCTAssertNotNil(children)
        XCTAssertEqual(children!.count, 2)
        XCTAssertEqual(children!.first!.name, tag.name)
        XCTAssertEqual(children![1].name, category.name)
    }


    func testTypeValidation() {
        let parent = createStatsRecord(in: mainContext, type: .tagsAndCategories, date: Date())

        let tag = TagsCategoriesStatsRecordValue(parent: parent)
        tag.name = "test"
        tag.type = 9001

        XCTAssertThrowsError(try mainContext.save()) { error in
            XCTAssertEqual(error._domain, StatsCoreDataValidationError.invalidEnumValue._domain)
            XCTAssertEqual(error._code, StatsCoreDataValidationError.invalidEnumValue._code)
        }
    }

    func testProperTypeForChildrenValidation() {
        let parent = createStatsRecord(in: mainContext, type: .tagsAndCategories, date: Date())

        let tag = TagsCategoriesStatsRecordValue(parent: parent)
        tag.name = "test"
        tag.type = TagsCategoriesType.tag.rawValue

        let category = TagsCategoriesStatsRecordValue(context: mainContext)
        category.name = "Category"
        category.type = TagsCategoriesType.category.rawValue

        tag.addToChildren(category)

        XCTAssertThrowsError(try mainContext.save()) { error in
            XCTAssertEqual(error._domain, StatsCoreDataValidationError.invalidEnumValue._domain)
            XCTAssertEqual(error._code, StatsCoreDataValidationError.invalidEnumValue._code)
        }
    }

    func testMultipleTagsAndCategories() {
        let parent = createStatsRecord(in: mainContext, type: .tagsAndCategories, date: Date())

        let tag = TagsCategoriesStatsRecordValue(parent: parent)
        tag.name = "Tag"
        tag.type = TagsCategoriesType.tag.rawValue

        let category = TagsCategoriesStatsRecordValue(parent: parent)
        category.name = "Category"
        category.type = TagsCategoriesType.category.rawValue

        let fr = StatsRecord.fetchRequest(for: .tagsAndCategories)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 2)

        let tagsAndCategories = results.first?.values?.array as! [TagsCategoriesStatsRecordValue]

        let tags = tagsAndCategories.filter { $0.type == TagsCategoriesType.tag.rawValue }
        let categories = tagsAndCategories.filter { $0.type == TagsCategoriesType.category.rawValue }

        XCTAssertEqual(tags.count, 1)
        XCTAssertEqual(categories.count, 1)

        XCTAssertEqual(tags.first!.name, tag.name)
        XCTAssertEqual(categories.first!.name, category.name)
    }

    func testURLConversionWorks() {
        let parent = createStatsRecord(in: mainContext, type: .tagsAndCategories, date: Date())

        let tag = TagsCategoriesStatsRecordValue(parent: parent)
        tag.urlString = "www.wordpress.com"

        let fetchRequest = StatsRecord.fetchRequest(for: .tagsAndCategories)
        let result = try! mainContext.fetch(fetchRequest)

        let fetchedValue = result.first!.values!.firstObject as! TagsCategoriesStatsRecordValue
        XCTAssertNotNil(fetchedValue.linkURL)
    }

    func testCoreDataConversionWorks() {
        let standaloneTag = StatsTagAndCategory(name: "standalone", kind: .tag, url: "wp.com/tags/tag", viewsCount: 0, children: [])

        let childTag = StatsTagAndCategory(name: "tag", kind: .tag, url: "whatever", viewsCount: 9001, children: [])
        let childCategory = StatsTagAndCategory(name: "category", kind: .category, url: "", viewsCount: 9002, children: [])

        let folderInsight = StatsTagAndCategory(name: "folder",
                                                kind: .folder,
                                                url: "https://wordpress.com",
                                                viewsCount: 18003,
                                                children: [childTag, childCategory])

        let insight = StatsTagsAndCategoriesInsight(topTagsAndCategories: [folderInsight, standaloneTag])

        let blog = defaultBlog()

        _ = StatsRecord.record(from: insight, for: blog)

        XCTAssertNoThrow(try mainContext.save())

        let fetchRequest = StatsRecord.fetchRequest(for: .tagsAndCategories)

        let result = try! mainContext.fetch(fetchRequest)
        let statsRecord = result.first!

        XCTAssertEqual(statsRecord.blog, blog)
        XCTAssertEqual(statsRecord.period, StatsRecordPeriodType.notApplicable.rawValue)

        let castedResults = statsRecord.values?.array as! [TagsCategoriesStatsRecordValue]

        XCTAssertEqual(castedResults.count, 2)

        let tag = castedResults.first { $0.type == TagsCategoriesType.tag.rawValue }
        XCTAssertNotNil(tag)

        XCTAssertEqual(tag?.name, "standalone")
        XCTAssertEqual(tag?.type, TagsCategoriesType.tag.rawValue)
        XCTAssertEqual(tag?.viewsCount, 0)
        XCTAssertEqual(tag?.linkURL, URL(string: "wp.com/tags/tag"))
        XCTAssertEqual(tag?.children?.count, 0)

        let folder = castedResults.first { $0.type == TagsCategoriesType.folder.rawValue }

        XCTAssertNotNil(folder)

        XCTAssertEqual(folder?.name, "folder")
        XCTAssertEqual(folder?.type, TagsCategoriesType.folder.rawValue)
        XCTAssertEqual(folder?.viewsCount, 18003)
        XCTAssertEqual(folder?.linkURL, URL(string: "https://wordpress.com"))

        XCTAssertEqual(folder?.children?.count, 2)

        let firstChild = folder?.children?[0] as? TagsCategoriesStatsRecordValue
        let secondChild = folder?.children?[1] as? TagsCategoriesStatsRecordValue

        XCTAssertNotNil(firstChild)
        XCTAssertNotNil(secondChild)

        XCTAssertEqual(firstChild?.name, "tag")
        XCTAssertEqual(firstChild?.type, TagsCategoriesType.tag.rawValue)
        XCTAssertEqual(firstChild?.viewsCount, 9001)
        XCTAssertEqual(firstChild?.linkURL, URL(string: "whatever"))

        XCTAssertEqual(secondChild?.name, "category")
        XCTAssertEqual(secondChild?.type, TagsCategoriesType.category.rawValue)
        XCTAssertEqual(secondChild?.viewsCount, 9002)
        XCTAssertEqual(secondChild?.linkURL, nil)
    }

}
