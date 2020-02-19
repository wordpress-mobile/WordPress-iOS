## Workflows Naming Convention

Whenever possible, follow this naming convention for workflows:

```yaml
# Use a short descriptive name for the whole workflow
name: Validate PR Labels
on: ...

jobs:
  # Use a present-tense verb as the name for the job, aligned with the workflow name
  validate:
    steps:
      # Omit names for steps using an action
      - uses: actions/checkout@v2

      ...

      # Keep using short present-tense names for steps that set up the stage
      - name: Install Yarn
        run: npm install -g yarn

      ...

      # Use the same present-tense name as the job for its core step, if any
      - name: Validate
        run: ...
```
