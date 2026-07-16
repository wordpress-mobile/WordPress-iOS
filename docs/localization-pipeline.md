# Localization translation pipeline

How user-facing strings get from English source into every shipped locale. This is the **release/tooling** view (the fastlane lanes under `fastlane/lanes/`); for how to *write* localizable strings in app code, see [localization.md](./localization.md).

> The contract for every shipped string is **`human ?? AI ?? English`**: a human (GlotPress) translation if one exists, otherwise a machine translation, otherwise the English source. Nothing ships a broken placeholder — **any** translation, human or machine, that fails the format-specifier gate is rejected and falls through to the next rung.

## The round trip

Strings make two trips, both driven from fastlane.

### Forward — English → GlotPress

Runs at code freeze and again with each beta (`generate_strings_file_for_glotpress`):

- **Regular strings** are extracted from source (`ios_generate_strings_file_from_code`, i.e. `genstrings` over `NSLocalizedString` / `AppLocalizedString`) into `WordPress/Resources/en.lproj/Localizable.strings`, then the manually-maintained `.strings` files are merged in. These English originals are uploaded to the [apps/ios GlotPress project](https://translate.wordpress.org/projects/apps/ios/dev/).
- **Plurals** are authored in `WordPress/Classes/Plurals.xcstrings` (English `one`/`other`). The forward lane (`generate_plural_strings_for_glotpress`) flattens each plural form into an independent string keyed `<key>|==|plural.<cldr-category>` and merges those originals into the same `Localizable.strings`, so they ride the same GlotPress project as everything else.

Translators then do their work in GlotPress.

### Reverse (release prep) — GlotPress → app

`download_localized_strings` runs with each beta and at release finalization — never at code freeze, when translators haven't yet seen the new originals. It runs, in order:

1. **Download** each locale's `Localizable.strings` from GlotPress (`ios_download_strings_files_from_glotpress`) into `WordPress/Resources/<locale>.lproj/`, and commit. The export filter is `status: current`, so **only translated strings come back** — untranslated ones are *omitted entirely* (not emitted as empty values — the download action checks for empties and flags them in the log as a GlotPress bug). This is why `hu`'s file carries only ~160 of the ~4,280 keys while `fr`'s carries ~4,220.
2. **Re-dispatch** the relevant subset back to the manually-maintained `.strings` files (`ios_extract_keys_from_strings_files`), and commit.
3. **Plural fold** (`download_localized_plurals`): pull the flat plural translations back out of the downloaded `Localizable.strings`, fold them into `Plurals.xcstrings`, and fill the gaps with the AI tier (below).

Step 3 runs via `run_plural_step`, which logs and continues on failure — the AI tier can never break a release.

## The AI tier

The machine-translation rung of the floor. It is **injected and gated**, never mandatory:

- **Gate**: `ANTHROPIC_API_KEY`. Absent ⇒ the AI tier is skipped entirely and untranslated cells keep their English fallback — i.e. exactly the pre-AI behavior. Providing the key (e.g. in the release environment) is what turns it on.
- **Placeholder gate**: every machine cell must preserve the source's `printf`/`NSString` format specifiers exactly (count + type; positional `%1$@` may reorder). A mismatch is rejected and the cell falls back to English. So the AI tier can only ever produce a *safe* translation or nothing.
- **Model**: `claude-opus-4-8` by default (see `AITranslator::DEFAULT_MODEL`).

The reusable primitives live in `fastlane/lanes/`: `AITranslator` (prompt building + validation; `translate` / `translate_plural` / `translate_all` / the async Message-Batches path), `TranslationValidator` (the placeholder gate), `Glossary` (brand do-not-translate list + per-locale terms), and `AnthropicBatch` (SDK glue). All the logic is pure and unit-tested with a canned-reply lambda; only `AITranslator.with_anthropic` touches the network.

## What's wired today: plurals

The plural reverse-fold (`PluralStrings.fold_translations!`) fills each `(key, locale)` cell of `Plurals.xcstrings` as `human ?? AI ?? English` — human ⇒ `translated`; AI / English ⇒ `needs_review`. The AI tier is called **once per `(key, locale)` form-set** (`AITranslator#translate_plural`), not per cell, with the forms already in hand — human translations plus machine cells kept from a prior fold — passed as **anchors**. Translating the whole set in one request keeps a single consistent stem across the forms — a per-category call lets the model drift between synonyms (Polish `słowo` → `wyrazy` → `słów`), which it structurally can't prevent.

**`Plurals.xcstrings` is a String Catalog, which is why this works**: the catalog carries a real `needs_review` state, so a machine cell is recorded as machine output, a human translation supersedes it on the next download, and an unchanged machine cell is carried over as-is on a re-fold rather than re-translated. The fold is idempotent — necessary, since the reverse runs with every beta: a re-run with the same input never churns the staged text, and kept machine cells aren't re-translated. Two kinds of cell do re-query the model each run: those that previously fell back to English (deliberate — a transient failure gets retried next time), and the `en-*` variant locales, where a correct translation is indistinguishable from the English fallback and so can never be kept.

> **This does not ship machine translations yet.** `Plurals.xcstrings` is built into the app but **not consumed at runtime** — nothing reads the catalog, and nothing references its keys yet; the app still renders plurals the legacy way. The fold *pre-populates* the catalog so it's ready when plurals cut over to it. Until that cutover, the AI plural translations sit in the catalog unused.

## What's staged, not shipped: regular strings

Regular (non-plural) strings still ship the legacy way — from `WordPress/Resources/<locale>.lproj/Localizable.strings`, with no machine translation. A machine translation written there would be **live immediately**, and we don't want machine-translated regular strings shipping before the catalog cutover. `Localizable.xcstrings` (`generate_strings_catalog`) is the designated future backing store; it's gitignored and not a build member, so nothing ships from it.

The tooling to **stage** regular-string translations into that catalog now exists, the same shape as the plural fold. `CatalogStrings.fold_translations!` fills each `(key, locale)` cell of `Localizable.xcstrings` as `human ?? AI ?? English` — human ⇒ `translated`, machine / English ⇒ `needs_review` — and is reuse-aware in the same way: a kept machine cell isn't re-translated, and a human translation supersedes it on the next fold. It runs as two manual lanes: `generate_strings_catalog` (extract the English source) and `localize_catalog` (download GlotPress into a throwaway temp dir, fold the humans in, AI-fill the rest, commit the catalog). The download is a fresh temp dir every run, so no stale/partial translation state is ever carried between runs.

Two things keep it from shipping anything today, and both set it apart from the plural fold:

- **Manual, not in the release path.** These lanes aren't wired into `download_localized_strings` or any beta/release step — a run extracts strings, calls the API (cost), and commits a large catalog, so it's run on demand. Only the unit tests run in CI.
- **Staged, not shipped.** `Localizable.xcstrings` still isn't the runtime store, so the folded translations sit in the catalog unused until the cutover — exactly like the plural catalog.

**Keys are immutable.** `generate_strings_catalog` hard-fails if an explicit-key string's English is reworded in place — `xcstringstool sync` would silently keep that key's now-stale translations, and the fold can't tell a translation of the old English from a current one. Rewording requires a **new key**. Key-as-source strings are exempt: rewording one changes the key, which sync handles as new/stale. (Enforcement today fires where the catalog persists; extending it to the transient-catalog CI path is a follow-up — a lint on the committed English `.strings`.)

Two facts the fold relies on, both established by the reverse download:

- **"Undefined by GlotPress" = absent**, not empty. The export omits untranslated strings (`status: current`; verified no empty-valued entries), so absence is the untranslated signal.
- **Humans always supersede MT**, and machine output never returns to GlotPress — so there's no translation-memory pollution and no manual reconciliation, as long as MT lives in a state-bearing store (the catalog's `needs_review`).

## Why these choices

- **Why translate whole plural form-sets at once?** Per-category calls let the model pick different synonyms for different forms of the same word. One request for the whole set, with human forms as anchors, keeps one stem.
- **Why is the AI tier gated and non-fatal?** Cost and safety: it runs only where a key is configured, and a failure logs and continues rather than breaking a release.
- **Why does regular-string MT need the catalog, not legacy `.strings`?** The catalog's `needs_review` state lets a machine translation be *staged* (built but not shipped until cutover) and lets humans supersede it automatically. Legacy `.strings` has no state and is live, so anything written there ships immediately — which is exactly what we don't want before cutover.

## Operational notes

- **Eyeball one string against the live model** (needs `ANTHROPIC_API_KEY` + `bundle install`):
  `bundle exec ruby fastlane/lanes/ai_translator.rb fr "You have %1$d new posts" "Notification text. %1$d is the count."`
- **Tests** are pure stdlib minitest and run in CI (`.buildkite/commands/test-localization-tooling.sh`): `ruby fastlane/lanes/*_test.rb`.

## Code map

| Concern | File |
| --- | --- |
| Translation tier (prompts, validation, `translate*`) | `fastlane/lanes/ai_translator.rb` |
| Placeholder safety gate | `fastlane/lanes/translation_validator.rb` |
| Brand do-not-translate + per-locale terms | `fastlane/lanes/translation_glossary.rb` |
| Anthropic SDK glue + Message Batches | `fastlane/lanes/anthropic_batch.rb` |
| Plural fold (`Localizable.strings` ⇄ `Plurals.xcstrings`) + AI wiring | `fastlane/lanes/plural_strings_helper.rb`, `fastlane/lanes/localization_plurals.rb` |
| Catalog generation + regular-string fold (staged, manual) | `fastlane/lanes/localization_catalog.rb`, `fastlane/lanes/catalog_strings_helper.rb` |
| Download/upload orchestration | `fastlane/lanes/localization.rb` |
