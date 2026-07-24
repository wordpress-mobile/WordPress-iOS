# Publish a Post with Category and Tag

## Prerequisites
- Logged in to the app with the test account.
- XML-RPC is disabled on the test site. The app should use the Core REST editor.
- The site has at least one existing category, such as "Uncategorized".

## Steps
1. Navigate to the "My Site" tab.
2. Tap the FAB (floating action button) or "+" button to create a new post.
3. If a bottom sheet appears, select "Post".
4. Enter "Category tag post" as the post title.
5. Tap below the title to add a paragraph block.
6. Type "This is a test post with category and tag." as the paragraph content.
7. Open the post settings (tap the gear/settings icon or "Post Settings").
8. Under "Categories", select an existing category, such as "Uncategorized".
9. Under "Tags", add a new tag with a more than 8 characters long random name.
10. Save the post settings.
11. Tap the "Publish" button in the top-right corner.
12. If a pre-publish confirmation appears, confirm by tapping "Publish" again.
13. Confirm publishing completes without an error alert. Do not require a separate post-publish confirmation screen.

## Verification (REST API)
- Use the WordPress REST API to search for a post titled "Category tag post" with status "publish".
- Verify the post exists and has the selected category and tag assigned.

## Cleanup (REST API)
- Use the WordPress REST API to trash the post created during this test.
- Delete the tag created during this test.

## Expected Outcome
- The post is published through the app without an XML-RPC or other publishing error.
- The REST API confirms a published post with the title "Category tag post" exists with the correct category and tag.
- The post and tag created during the test are cleaned up via the REST API.
