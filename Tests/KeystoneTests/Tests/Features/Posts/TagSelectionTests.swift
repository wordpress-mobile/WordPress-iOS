import Foundation
import Testing
import WordPressAPI

@testable import WordPress

@MainActor
struct TagSelectionTests {

    @Test
    func addNewTag() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        #expect(await mock.tags.count == 2)

        let viewModel = TagsViewModel(taxonomy: nil, service: mock, selectedTerms: nil, mode: .selection(onSelectedTagsChanged: nil))
        await viewModel.addNewTag(named: "Baz")?.value
        await #expect(mock.tags.count == 3)
    }

    @Test
    func addExistingTag() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        #expect(await mock.tags.count == 2)

        let viewModel = TagsViewModel(taxonomy: nil, service: mock, selectedTerms: nil, mode: .selection(onSelectedTagsChanged: nil))
        await viewModel.addNewTag(named: "Foo")?.value
        #expect(await mock.tags.count == 2)
    }

    @Test
    func newTagIsSelected() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        let viewModel = TagsViewModel(taxonomy: nil, service: mock, selectedTerms: nil, mode: .selection(onSelectedTagsChanged: nil))
        await viewModel.addNewTag(named: "Baz")?.value

        #expect(await viewModel.selectedTags == ["Baz"])
    }

    @Test
    func serverTagIsSelected() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        let viewModel = TagsViewModel(taxonomy: nil, service: mock, selectedTerms: nil, mode: .selection(onSelectedTagsChanged: nil))
        await viewModel.addNewTag(named: "foo")?.value

        #expect(await viewModel.selectedTags == ["Foo"])
    }

    @Test
    func toggleSelection() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        let tags = await mock.tags
        let viewModel = TagsViewModel(taxonomy: nil, service: mock, selectedTerms: nil, mode: .selection(onSelectedTagsChanged: nil))
        #expect(viewModel.selectedTags.isEmpty)

        viewModel.toggleSelection(for: tags[0])
        #expect(viewModel.selectedTags.count == 1)

        viewModel.toggleSelection(for: tags[0])
        #expect(viewModel.selectedTags.count == 0)
    }

}

private actor MockService: TaxonomyServiceProtocol {
    var tags: [AnyTermWithViewContext]

    init(tags: [String] = []) {
        self.tags = tags.map {
            AnyTermWithViewContext(
                id: (1...Int64.max).randomElement()!,
                count: 0,
                description: "",
                link: "",
                name: $0,
                slug: $0.lowercased(),
                taxonomy: .postTag,
                parent: nil
            )
        }
    }

    func getTags(page: Int, recentlyUsed: Bool) async throws -> [AnyTermWithViewContext] {
        tags
    }

    func searchTags(with query: String) async throws -> [AnyTermWithViewContext] {
        tags.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func createTag(name: String, description: String) async throws -> AnyTermWithViewContext {
        let lowercasedName = name.lowercased()
        if tags.contains(where: { $0.name.lowercased() == lowercasedName }) {
            let error = NSError(domain: "MockService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tag already exists"])
            throw error
        }

        let newTag = AnyTermWithViewContext(
            id: (1...Int64.max).randomElement()!,
            count: 0,
            description: description,
            link: "",
            name: name,
            slug: name.lowercased(),
            taxonomy: .postTag,
            parent: nil
        )
        tags.append(newTag)
        return newTag
    }

    func updateTag(_ term: AnyTermWithViewContext, name: String, description: String) async throws -> AnyTermWithViewContext {
        guard let index = tags.firstIndex(where: { $0.id == term.id }) else {
            let error = NSError(domain: "MockService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Tag not found"])
            throw error
        }

        let updatedTag = AnyTermWithViewContext(
            id: term.id,
            count: term.count,
            description: description,
            link: term.link,
            name: name,
            slug: name.lowercased(),
            taxonomy: term.taxonomy,
            parent: term.parent
        )
        tags[index] = updatedTag
        return updatedTag
    }

    func deleteTag(_ term: AnyTermWithViewContext) async throws {
        tags.removeAll { $0.id == term.id }
    }
}
