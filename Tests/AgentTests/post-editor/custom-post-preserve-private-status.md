# Preserve Private Visibility When Publishing a Custom Post

Regression test for the bug where publishing a REST custom post from the pre-publishing sheet flattens a user-selected `private` visibility to a public `publish`.

## Prerequisites
- Logged in to the app with the test account.
- The site has at least one custom post type registered with REST API support, and the custom post types entry is visible on the My Site screen. If no custom post type is available, fail with "Prerequisite not met: site has no REST custom post type".

## Steps
1. Navigate to the "My Site" tab.
2. From the blog details menu, tap the **"More"** row (uses an ellipsis icon) to open the Custom Post Types list.
3. Tap one of the available custom post types (e.g., "Books").
4. Tap the FAB (floating "+" button in the bottom-right corner) to create a new custom post.
5. Enter "CPT private preserve" as the post title.
6. Tap the "Publish" button in the top-right corner to open the pre-publish sheet.
7. From the pre-publish sheet, open "Post Settings".
8. Change the visibility setting to "Private".
9. Return to the pre-publish sheet.
10. Tap "Publish" to commit.
11. Dismiss the confirmation screen by tapping "Done".

## Verification (REST API)
- Use the WordPress REST API endpoint for the chosen custom post type (e.g., `/wp/v2/<cpt-rest-base>?search=CPT+private+preserve&status=private`) to look up the post by title. Authenticate with the application password (private posts are not returned to anonymous requests).
- Verify a post titled "CPT private preserve" exists.
- **Regression assertion:** the post's `status` field is exactly `"private"`, not `"publish"`. A `status` of `"publish"` indicates the bug has regressed.

## Cleanup (REST API)
- Use the WordPress REST API to trash the post created during this test, regardless of pass or fail.

## Expected Outcome
- The custom post is published with private visibility and the REST API confirms `status: "private"`.
- The user's `private` selection from Post Settings is preserved on the publish path.
