# Undo and Redo in the Block Editor

## Prerequisites
- Logged in to the app with the test account.

## Steps
1. Navigate to the "My Site" tab.
2. Tap the FAB (floating action button) or "+" button to create a new post.
3. If a bottom sheet appears, select "Post".
4. Verify the Undo button is disabled.
5. Verify the Redo button is disabled.
6. Enter "Rich post title" as the post title.
7. Tap below the title to add a paragraph block.
8. Type "Lorem ipsum dolor sit amet" as the paragraph content.
9. Tap the Undo button twice to undo the paragraph and title.
10. Verify the editor content is empty (no blocks visible).
11. Tap the Redo button twice to restore the paragraph and title.
12. Verify the paragraph content "Lorem ipsum dolor sit amet" is visible again.

## Expected Outcome
- After undoing, the editor content is empty.
- After redoing, the title and paragraph content are restored.
- Undo and Redo buttons correctly reflect available actions throughout the flow.
