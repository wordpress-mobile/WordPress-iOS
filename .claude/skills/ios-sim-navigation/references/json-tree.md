# JSON Tree Format

Use JSON when you need to walk the accessibility tree programmatically. The
description format remains the smaller default for ordinary navigation.

Fetch JSON through the explicit session and save it rather than returning the
large payload into model context:

```bash
curl -s \
  "http://localhost:<PORT>/session/<SESSION_ID>/source?format=json" \
  | jq '.value' > /tmp/wda-tree.json
```

Each node can contain `type`, `label`, `name`, `value`, `rect`, `isEnabled`, and
`children`.

```bash
# Find a node by accessibility identifier.
jq '.. | objects | select(.name == "post-title")' /tmp/wda-tree.json

# Find a node by visible label.
jq '.. | objects | select(.label == "Settings")' /tmp/wda-tree.json

# Match part of a dynamic label.
jq '.. | objects | select(.label? // "" | contains("Posts"))' \
  /tmp/wda-tree.json

# Read a text field value.
jq '.. | objects | select(.name == "post-title") | .value' \
  /tmp/wda-tree.json
```

For one known element, use its targeted attribute endpoint instead of dumping
the full tree.
