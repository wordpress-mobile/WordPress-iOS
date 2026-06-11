# Undo and Redo in the Block Editor

## Prerequisites
- Logged in to the app with the test account.

## Steps
1. Navigate to the "My Site" tab.
2. Tap the FAB (floating action button) or "+" button to create a new post.
3. If a bottom sheet appears, select "Post".
4. Verify the Undo button is disabled.
5. Verify the Redo button is disabled.
6. Enter "Undo test" as the post title.
7. Tap below the title to add a paragraph block.
8. Type "Test" as the paragraph content.
9. Tap the Undo button until the typed title and paragraph text are no longer visible and the Undo button becomes disabled.
   Undo is granular, so it may take several taps. Stop as soon as Undo is disabled. Do not tap Undo more than 15 times.
10. Verify the typed title and paragraph text are no longer visible, and the Undo button is disabled.
    Empty title or paragraph placeholders may still be visible.
11. Tap the Redo button until the title and paragraph are restored and the Redo button becomes disabled.
    Redo is granular, so it may take several taps. Stop as soon as Redo is disabled. Do not tap Redo more than 15 times.
12. Verify the title "Undo test" and paragraph content "Test" are visible again, and the Redo button is disabled.

## Expected Outcome
- After undoing all edits, the typed title and paragraph text are gone and the Undo button is disabled.
- After redoing all edits, the title and paragraph content are restored and the Redo button is disabled.
- Undo and Redo buttons correctly reflect available actions throughout the flow.
