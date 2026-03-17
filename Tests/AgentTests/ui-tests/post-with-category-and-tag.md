# Publish a Post with Category and Tag

## Prerequisites
- Logged in to the app with the test account.
- The site has a category named "Wedding" (or another existing category).

## Steps
1. Navigate to the "My Site" tab.
2. Tap the FAB (floating action button) or "+" button to create a new post.
3. If a bottom sheet appears, select "Post".
4. Enter "Category tag post" as the post title.
5. Tap below the title to add a paragraph block.
6. Type "This is a test post with category and tag." as the paragraph content.
7. Open the post settings (tap the gear/settings icon or "Post Settings").
8. Under "Categories", select an existing category (e.g., "Wedding").
9. Under "Tags", add a new tag with a more than 8 characters long random name.
10. Save the post settings.
11. Tap the "Publish" button in the top-right corner.
12. If a pre-publish confirmation appears, confirm by tapping "Publish" again.
13. Verify the post-publish confirmation screen shows the correct post title.
14. Dismiss the confirmation screen by tapping "Done".

## Verification (REST API)
- Use the WordPress REST API to search for a post titled "Category tag post" with status "publish".
- Verify the post exists and has the expected category (e.g., "Wedding") and tag assigned.

## Cleanup (REST API)
- Use the WordPress REST API to trash the post created during this test.

## Expected Outcome
- The post is published with the selected category and tag.
- The post-publish confirmation screen displays the correct post title.
- The REST API confirms a published post with the title "Category tag post" exists with the correct category and tag.
- The post is trashed via the REST API.
