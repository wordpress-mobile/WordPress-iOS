# Create and Publish a Blank Page

## Prerequisites
- Logged in to the app with the test account.

## Steps
1. Navigate to the "My Site" tab.
2. Tap the FAB (floating action button) or "+" button to create new content.
3. In the bottom sheet, select "Page".
4. If a page template picker appears, select "Blank page" to create a blank page.
5. Enter "Blank page title" as the page title.
6. Tap the "Publish" button in the top-right corner.
7. If a pre-publish confirmation appears, confirm by tapping "Publish" again.
8. Dismiss the post-publish confirmation screen by tapping "Done".

## Verification (REST API)
- Use the WordPress REST API to search for a page titled "Blank page title" with status "publish".
- Verify the page exists.

## Cleanup (REST API)
- Use the WordPress REST API to trash the page created during this test.

## Expected Outcome
- The page "Blank page title" is published successfully and a confirmation screen is shown.
- The REST API confirms a published page with the title "Blank page title" exists.
- The page is trashed via the REST API.
