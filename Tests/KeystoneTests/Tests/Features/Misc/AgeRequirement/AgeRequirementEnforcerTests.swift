import CoreData
import Testing
import WordPressData

@testable import WordPress

@Suite("Age requirement enforcer")
@MainActor
struct AgeRequirementEnforcerTests {
    @Test("Removes only sites without an account and their local drafts")
    func removeSelfHostedSites() async throws {
        let contextManager = ContextManager.forTesting()
        let context = contextManager.mainContext
        let wpComBlog = BlogBuilder(context).isHostedAtWPcom().withAnAccount().build()
        let jetpackBlog = BlogBuilder(context).isNotHostedAtWPcom().withAnAccount().build()
        let firstSelfHostedBlog = BlogBuilder(context).isNotHostedAtWPcom().build()
        let secondSelfHostedBlog = BlogBuilder(context).isNotHostedAtWPcom().build()
        let localDraft = PostBuilder(context, blog: secondSelfHostedBlog).drafted().build()
        contextManager.saveContextAndWait(context)

        let enforcer = AgeRequirementEnforcer(coreDataStack: contextManager, windowManager: { nil })
        #expect(enforcer.userState.selfHostedSiteCount == 2)

        enforcer.removeSelfHostedSites()

        let remaining = try await contextManager.performQuery { context in
            let blogs = try context.fetch(NSFetchRequest<Blog>(entityName: Blog.entityName()))
            let posts = try context.fetch(NSFetchRequest<Post>(entityName: Post.entityName()))
            return (Set(blogs.map(\.objectID)), Set(posts.map(\.objectID)))
        }
        #expect(remaining.0 == Set([wpComBlog.objectID, jetpackBlog.objectID]))
        #expect(!remaining.0.contains(firstSelfHostedBlog.objectID))
        #expect(!remaining.0.contains(secondSelfHostedBlog.objectID))
        #expect(!remaining.1.contains(localDraft.objectID))
    }
}
