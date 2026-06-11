# Raw W3C Actions and Less-Common Gestures

Use these only when `tap.rb` doesn't cover the gesture (long press,
multi-touch) or when you need to clear a text field. All examples assume
a bound `SESSION_ID` — see `references/sessions.md`.

```bash
SID=$(jq -r .session_id /tmp/wda-8100.session)
```

## Long Press

A `pause` between `pointerDown` and `pointerUp`. Duration is milliseconds.

```bash
curl -s -X POST http://localhost:8100/session/$SID/actions \
  -H 'Content-Type: application/json' \
  -d '{
    "actions": [{
      "type": "pointer", "id": "finger1",
      "parameters": {"pointerType": "touch"},
      "actions": [
        {"type": "pointerMove", "duration": 0, "x": X, "y": Y},
        {"type": "pointerDown"},
        {"type": "pause", "duration": 1000},
        {"type": "pointerUp"}
      ]
    }]
  }'
```

## Clear Text Field

**Both methods below are unreliable on iOS 26** — verified to silently
no-op against `SearchField` and similar controls. Prefer the field's own
clear control (the small X icon present on most search/text fields) or
tap-and-hold to bring up the iOS edit menu.

If you must try the programmatic path, **always read the field's
`value` attribute afterwards to confirm it actually cleared.** Don't
trust the HTTP 200.

```bash
# Select all (Ctrl+A) then delete
curl -s -X POST http://localhost:8100/session/$SID/wda/keys \
  -H 'Content-Type: application/json' \
  -d '{"value": ["\u0001"]}'
curl -s -X POST http://localhost:8100/session/$SID/wda/keys \
  -H 'Content-Type: application/json' \
  -d '{"value": ["\u007F"]}'
```

Alternatively, if you have an element id:

```bash
curl -s -X POST http://localhost:8100/session/$SID/element/ELEMENT_ID/clear
```

## Back Navigation Deep-Dive

To return to the previous screen:

- **Primary**: find a Button inside `NavigationBar`. Its label is
  typically the previous screen's title. Tap it via
  `tap.rb text "<Prev Title>"` (with `--wait-aid` for the destination's
  marker).
- **Fallback**: edge swipe from `(5, H/2)` to `(W*2/3, H/2)`.

The button approach is more reliable because edge swipes can be finicky
depending on gesture recognizers.
