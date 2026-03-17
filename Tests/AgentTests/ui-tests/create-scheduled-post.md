# Create a Scheduled Post

## Prerequisites
- Logged in to the app with the test account.

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
10. Dismiss the confirmation screen by tapping "Done".

## Verification (REST API)
- Use the WordPress REST API to search for a post titled "Scheduled post title" with status "future".
- Verify the post exists and has a future publish date.

## Cleanup (REST API)
- Use the WordPress REST API to trash the post created during this test.

## Expected Outcome
- The post is scheduled for a future date and a confirmation screen is shown.
- The REST API confirms a post with the title "Scheduled post title" exists with status "future".
- The post is trashed via the REST API.
