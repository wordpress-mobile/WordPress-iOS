# JSON Tree Format

The default tree format (`format=description`) is plaintext and grep-friendly
and covers ~90% of needs. Reach for `format=json` when you need to walk the
tree programmatically — for example reading a specific element's `value`
attribute after typing into it, or finding all elements matching a filter.

```bash
curl -s 'http://localhost:8100/source?format=json' > /tmp/wda-tree.json
```

The JSON tree is ~375 KB (vs ~25 KB for description), so save to a file
and `jq` against it rather than piping it through your conversation
context.

## Node shape

Each node has these fields:

| Field | Description |
|-------|-------------|
| `type` | Element type (`Button`, `StaticText`, …) |
| `label` | Accessibility label (user-visible text) |
| `name` | Accessibility identifier (developer-assigned id) |
| `value` | Current value (text field contents, switch state, …) |
| `rect` | `{"x": N, "y": N, "width": N, "height": N}` |
| `isEnabled` | Whether interactive |
| `children` | Array of child nodes |

## Common jq patterns

```bash
# Find a node by accessibility identifier.
jq '.. | objects | select(.name == "post-title")' /tmp/wda-tree.json

# Find a node by visible label.
jq '.. | objects | select(.label == "Settings")' /tmp/wda-tree.json

# Partial match on label.
jq '.. | objects | select(.label? // "" | contains("Posts"))' /tmp/wda-tree.json

# Read a text field's current value.
jq '.. | objects | select(.name == "post-title") | .value' /tmp/wda-tree.json
```

For reading a single attribute, the targeted `/element/<id>/attribute/<name>`
endpoint is cheaper than dumping the whole JSON tree. Use the full tree
only when you genuinely need to enumerate or filter across many nodes.
