# Raw WDA Actions

Use raw actions only when the bundled scripts do not cover the gesture. Every
request must use the selected port and explicit session ID.

## Long press

```bash
curl -s -X POST \
  "http://localhost:<PORT>/session/<SESSION_ID>/actions" \
  -H 'Content-Type: application/json' \
  -d '{
    "actions": [{
      "type": "pointer",
      "id": "finger1",
      "parameters": { "pointerType": "touch" },
      "actions": [
        { "type": "pointerMove", "duration": 0, "x": 196, "y": 400 },
        { "type": "pointerDown" },
        { "type": "pause", "duration": 1000 },
        { "type": "pointerUp" }
      ]
    }]
  }'
```

## Send keys and control codes

The normal path is `type.rb`. Use `/wda/keys` directly only for control-code
sequences:

```bash
# Control-A, then replacement text.
curl -s -X POST \
  "http://localhost:<PORT>/session/<SESSION_ID>/wda/keys" \
  -H 'Content-Type: application/json' \
  -d '{"value":["\u0001","replacement"]}'
```

## Clear a field

On iOS 26, `/element/<id>/clear` can be inconsistent with nested SwiftUI text
inputs. Prefer focusing the field, sending Control-A, then typing replacement
text. Use the direct clear endpoint only when the element supports it:

```bash
curl -s -X POST \
  "http://localhost:<PORT>/session/<SESSION_ID>/element/<ELEMENT_ID>/clear"
```

## Edge-swipe back

Use the bundled helper before constructing raw actions:

```bash
ruby scripts/swipe.rb back --port <PORT> --session-id <SESSION_ID>
```
