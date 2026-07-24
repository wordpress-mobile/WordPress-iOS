# Create a Scheduled Post

## Prerequisites
- Logged in to the app with the test account.
- The XML-RPC endpoint is blocked on the test site. The app should use the Core REST editor.

## Steps
1. Navigate to the "My Site" tab.
2. Tap the FAB (floating action button) or "+" button to create a new post.
3. If a bottom sheet appears, select "Post".
4. Enter "Scheduled post title" as the post title.
5. Tap the "Publish" button in the top-right corner.
6. In the pre-publish sheet, tap the publish date to change it.
7. Set the date to a future date (e.g., one day from now).
8. Confirm the date selection.
9. Tap "Schedule" to schedule the post.
10. Confirm scheduling completes without an error alert. Do not require a separate post-publish confirmation screen.

## Verification (REST API)
- Use the WordPress REST API to search for a post titled "Scheduled post title" with status "future".
- Verify the post exists and has a future publish date.

## Cleanup (REST API)
- Use the WordPress REST API to trash the post created during this test.

## Expected Outcome
- The post is scheduled through the app without an XML-RPC or other publishing error.
- The REST API confirms a post with the title "Scheduled post title" exists with status "future".
- The post is trashed via the REST API.
