# Publish a Text Post

## Prerequisites
- Logged in to the app with the test account.

## Steps
1. Navigate to the "My Site" tab.
2. Tap the FAB (floating action button) or "+" button to create a new post.
3. If a bottom sheet appears, select "Post".
4. Enter "Rich post title" as the post title.
5. Tap below the title to add a paragraph block.
6. Type "Lorem ipsum dolor sit amet, consectetur adipiscing elit." as the paragraph content.
7. Tap the "Publish" button in the top-right corner.
8. If a pre-publish confirmation appears, confirm by tapping "Publish" again.
9. Dismiss the post-publish confirmation screen by tapping "Done".

## Verification (REST API)
- Use the WordPress REST API to search for a post titled "Rich post title" with status "publish".
- Verify the post exists.

## Cleanup (REST API)
- Use the WordPress REST API to trash the post created during this test.

## Expected Outcome
- The post "Rich post title" is published successfully and a confirmation screen is shown.
- The REST API confirms a published post with the title "Rich post title" exists.
- The post is trashed via the REST API.
