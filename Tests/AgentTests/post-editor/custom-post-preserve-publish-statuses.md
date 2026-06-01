# Preserve User-Selected Status When Publishing a Custom Post

Regression test for the bug where publishing a REST custom post from the pre-publishing sheet flattens a user-selected status (`private`, `pending`, or `future`/scheduled) to a public `publish`, discarding the user's intent.

## Prerequisites
- Logged in to the app with the test account.
- The site has at least one custom post type registered with REST API support, and the custom post types entry is visible on the My Site screen. If no custom post type is available, fail with "Prerequisite not met: site has no REST custom post type".

## Status Matrix

Perform the steps below **once per row**. Each row creates a separate post with its own title.

| Status    | Title                  | How to set it from the pre-publish sheet                                               |
| --------- | ---------------------- | -------------------------------------------------------------------------------------- |
| `private` | CPT private preserve   | Open "Post Settings" and set Visibility to "Private".                                  |
| `pending` | CPT pending preserve   | Scroll to "More Options" and toggle "Pending Review" on.                               |
| `future`  | CPT scheduled preserve | Tap the "Date" row and pick a date at least 7 days in the future, then confirm.        |

## Steps (per row)
1. From "My Site", tap **"More"**, then tap one of the available custom post types (e.g., "Books").
2. Tap the FAB ("+") to create a new custom post and enter the row's **Title**.
3. Tap **"Publish"** in the top-right corner to open the pre-publish sheet.
4. Apply the row's **"How to set it"** action.
5. Return to the pre-publish sheet. For `future`, the primary button changes from "Publish" to "Schedule".
6. Tap the primary button to commit. Dismiss the confirmation screen.

## Verification (per row, via REST API)
- Look up the post by title against the custom post type's REST endpoint (e.g., `/wp/v2/<cpt-rest-base>?search=<title>&status=any`). Authenticate with the application password — private and future posts aren't returned to anonymous requests.
- **Regression assertion:** the post's `status` field is exactly the row's `Status`. Any other value (especially `"publish"`) indicates the bug has regressed.

## Cleanup (REST API)
- Trash every post created during this test, regardless of pass or fail.

## Expected Outcome
- For each row, the custom post is saved with the user-selected status preserved through the publish path.
