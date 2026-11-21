# App Store Screenshots

The Jetpack and WordPress apps' App Store screenshots are made from the apps themselves, in every language the App Store listing is translated into. Making them takes three `fastlane` lanes per app:

| | Jetpack | WordPress |
|---|---|---|
| 1. [Take the raw screenshots](#taking-the-screenshots) | `jetpack_screenshots` | `wordpress_screenshots` |
| 2. [Add the headlines and device frames](#composing-the-screenshots) | `create_jetpack_promo_screenshots` | `create_promo_screenshots` |
| 3. [Upload them](#uploading-the-screenshots) | `update_jetpack_metadata_on_app_store_connect with_screenshots:true` | `update_wordpress_metadata_on_app_store_connect with_screenshots:true` |

Both apps use the same test, fixtures, devices and compositor. What differs:

| | Jetpack | WordPress |
|---|---|---|
| Screens | Stats, Editor, Reader, Notifications | Editor, Staff (a custom post type), Media, Pages |
| Raw screenshots | `fastlane/jetpack_screenshots/` | `fastlane/wordpress_screenshots/` |
| Headlines | `fastlane/appstoreres/jetpack_metadata/` | `fastlane/appstoreres/metadata/` |
| Final screenshots | `fastlane/jetpack_promo_screenshots/` | `fastlane/promo_screenshots/` |
| Title screen logo | WordPress and Jetpack | WordPress |

The WordPress app leaves Stats, the Reader and Notifications to the Jetpack app, and shows a poster about it in their place, so its screenshots show what it does have.

The WordPress screenshots load fixtures of their own over the UI tests' ones, from `fastlane/appstoreres/screenshot_fixtures/wordpress/`. They make the fixture site, Tri-County Real Estate, an Atomic site, since the app only shows custom post types on sites it reaches through the core REST API, and give it a Staff post type with four agents. The UI tests don't see any of it. An app's own fixtures are laid out like `Tests/JetpackUITests/Fixtures/mappings`, and replace any file there at the same path; their images go in the UI tests' `Fixtures/__files`, which is where `bodyFileName` is read from.

The agents' headshots are placeholders for now: Gravatar's generated `retro` patterns, in `Fixtures/__files/images/staff/`.

The examples below use the Jetpack lanes; the WordPress ones work the same way.

## Taking the screenshots

```bash
bundle exec fastlane jetpack_screenshots
```

This builds the Jetpack app with the [HTTP fixtures](ui-tests.md#fixtures) compiled in, then runs the `AppStoreScreenshots` UI test once for each device and language. Each run saves its screenshots to `fastlane/jetpack_screenshots/<locale>/`.

`wordpress_screenshots` builds the WordPress app with the fixtures too, and installs it on each simulator. The UI test target is Jetpack's, and it launches the WordPress app by its bundle identifier.

The test runs against the fixtures, so every screenshot shows the same account and content, and nothing reaches WordPress.com. It finds its way around by accessibility identifiers and the fixtures' content, never by the app's own text, so it works in every language.

| | Device | Size |
|---|---|---|
| iPhone | iPhone 18 Pro Max | 1320 × 2868 (6.9") |
| iPad | iPad Pro 13-inch (M5) | 2064 × 2752 (13") |
| iPhone Duo | iPhone Duo | 1398 × 2034 (outer display) and 2007 × 2853 (inner display) |

Each device gets a simulator of its own, called "Screenshots iPhone 18 Pro Max" and so on, which the lane creates the first time. It sets the simulator to light mode and its status bar to 9:41 with full signal and battery.

### On CI

```bash
bundle exec fastlane trigger_app_store_screenshots app:jetpack
bundle exec fastlane trigger_app_store_screenshots app:wordpress
```

This starts `.buildkite/app-store-screenshots.yml` on the current branch for one app, which needs a Buildkite API token in `BUILDKITE_TOKEN`. It builds once, on the Xcode 27.1 image, then runs a job per device and language: 51 jobs, in a matrix step per device, since a matrix can make at most 50. A last job composes whatever was taken, and its artifacts are the composed screenshots, zipped as `fastlane/<app>_promo_screenshots.zip` in the layout the upload lane reads, and the overview of each language.

A new language needs adding to the pipeline's `x-locales` list.

### The iPhone Duo

The iPhone Duo needs **Xcode 27.1 or later**: an app built with an older SDK runs letterboxed on its outer display. Run the lane with that Xcode selected, for every device, since they share one build:

```bash
DEVELOPER_DIR=/Applications/Xcode-27.1.0.app/Contents/Developer bundle exec fastlane jetpack_screenshots
```

The lane stops if the selected Xcode, or the app it's about to reuse with `skip_build:true`, is older than that. To leave the Duo out, name another device with `device:`.

The simulator only models the Duo's outer display. For the inner one, the lane moves the app to a resizable display the inner display's size, with `xcrun devicectl device appResize`, the way the Duo does when it's unfolded. XCUITest can't tap on that display, so the test captures each screen on the outer display, then asks the lane for the inner one through a file and waits, and the lane takes the screenshot, moves the app back and answers. Some screens don't lay themselves out for the outer display again after that, so on the Duo the test relaunches the app before each screen.

The emulated inner display has no status bar, so those screenshots have none.

Both displays' screenshots go in the App Store's one iPhone Duo set, the inner display's first. Uploading them needs fastlane 2.241.1 or later.

By default the lane takes screenshots in every language that has [all of its headlines](#the-headlines), since the others are left out. Taking them all takes a while (around three minutes per language and device, and more on the Duo), so while you're working on them, take one:

```bash
bundle exec fastlane jetpack_screenshots language:de-DE device:"iPhone 18 Pro Max" skip_build:true
```

`skip_build:true` reuses the app from the last run. `language` takes a comma-separated list.

### Temporary translations

For now, every App Store language has headlines and on-screen content translated by Claude, not by translators: the `screenshot_*.txt` files in each `fastlane/appstoreres/jetpack_metadata/<locale>/` and `fastlane/appstoreres/metadata/<locale>/` folder, and every `<locale>.json` in `fastlane/appstoreres/screenshot_content/`. The WordPress title, Editor, Media and My Site headlines reuse the translators' wording of the old WordPress screenshots, where it fits. They're placeholders until both go through the translation pipeline. The headlines are replaced the first time `download_jetpack_promo_strings` or `download_promo_strings` runs after GlotPress has them; the on-screen content has no pipeline yet.

### Translating what's on screen

The app's own text is in each language already. The content (post titles, the draft in the editor, the Reader post, notifications) comes from the fixtures, which are in English, so it's translated separately:

- `fastlane/appstoreres/screenshot_content/en.json` lists that content by key, exactly as it reads in the fixtures, HTML and curly quotes included.
- `<locale>.json` beside it has the translations, by the same keys. A key it leaves out stays in English, and the lane says which.

For each language with a translation, the lane writes a copy of every fixture file that has content to translate, with it translated, and the app loads those over the fixtures (the `-ui-test-http-fixtures-overlay` launch argument). The fixtures the UI tests assert on don't change. `fastlane/lanes/screenshot_content_helper.rb` does the translating:

- An entry of a few words or more is replaced wherever it appears, such as a paragraph inside a post. A shorter one, such as a post called "Home", only replaces a value that's exactly that, so it can't change a word inside other text. To translate a short heading inside HTML, include its tag in the entry, as `<strong>How to book</strong>` does.
- Notifications mark names and post titles in their text. A translation has to keep each of those, exactly as it's translated on its own, or the lane stops and says which.

To add content, find the screen's text in `Tests/JetpackUITests/Fixtures` or an app's own screenshot fixtures, add it to `en.json` exactly as it is there, and add its translations.

### Changing what's on screen

The screens are in `Tests/JetpackUITests/Screenshots/AppStoreScreenshots.swift`, numbered in the order they appear in the App Store. The content comes from the fixtures in `Tests/JetpackUITests/Fixtures`, which [docs/ui-tests.md](ui-tests.md#fixtures) describes. Images are served from `Fixtures/__files`: the avatars there are generated placeholders, not anyone's Gravatar.

The test is skipped in an ordinary run of the UI tests, because only the lane tells it where to save the screenshots.

## Composing the screenshots

```bash
bundle exec fastlane create_jetpack_promo_screenshots
```

This runs `Scripts/app-store-screenshots/compose.swift`, which writes the final screenshots to `fastlane/jetpack_promo_screenshots/<locale>/`, ready to upload. Each language gets a title screen with the app's logo, then each raw screenshot with its headline above it, in a device frame.

It also writes `fastlane/jetpack_screenshots_overview/<locale>-<device>.png`: every screenshot for one language and device, side by side. Look through these before uploading.

### How headlines are fitted to each language

A translation can be much longer than the English, or have no spaces between words, so the compositor fits each language's headlines rather than using a fixed size:

- **Size.** Each headline is set as large as it can be within two lines (three for the title screen), without breaking a word. All of a language's headlines then use the smallest of those sizes, so they look like a set.
- **Line breaks.** The lines are balanced, so a headline doesn't end with one word on a line of its own. Japanese and Chinese only break between phrases, using Apple's `NLTokenizer`, so a word is never split across lines.
- **Fonts.** Headlines are set in New York, the system serif. Scripts it doesn't cover use a serif font that ships with macOS: Hiragino Mincho for Japanese, Songti for Chinese, AppleMyungjo for Korean, Times New Roman for Arabic and New Peninim for Hebrew.
- **Layout.** Every device frame in a language sits at the same height, below a band as tall as its tallest headline.

A headline that doesn't fit in two lines even at the smallest size is set at that size on more lines, and the lane lists it at the end of its output. Ask for a shorter translation of those.

### The headlines

Each screenshot's headline is two strings: the feature's name, in bold ("Stats."), and the rest ("Your metrics, wherever you are."). They're separate so that every language gets its bold lead, without translators having to keep any formatting.

| File | Example |
|---|---|
| `screenshot_title.txt` | The best of WordPress in your pocket |
| `screenshot_<n>_feature.txt` | Stats. |
| `screenshot_<n>_headline.txt` | Your metrics, wherever you are. |

The English is in the app's headlines folder's `source/` (see the table at the top), and each translation in the folder for its locale. To change them:

1. Edit the files in `source`, and copy them to `en-US`.
2. The release process uploads them to GlotPress at code freeze, with the rest of the App Store strings (`update_appstore_strings`).
3. Once they're translated, run `bundle exec fastlane download_jetpack_promo_strings` (Jetpack) or `download_promo_strings` (WordPress) to download them.

The number of screenshots is in `SCREENSHOT_APPS` in `fastlane/lanes/screenshots.rb`.

A language without all of its headlines is left out of the final screenshots, and the App Store shows the English screenshots there instead. That's better than an English headline over a translated app.

## Uploading the screenshots

Once the final screenshots are in `fastlane/jetpack_promo_screenshots/<locale>/`:

```bash
bundle exec fastlane update_jetpack_metadata_on_app_store_connect with_screenshots:true
```

The App Store tells which device a screenshot is for by its size, and orders a device's screenshots by file name. Each run's log and result bundle are in `build/results/screenshots/`.

> [!NOTE]
> This uploads the app's other App Store metadata too: its name, subtitle, description and so on.

## Using screenshots a designer made

Either app can instead upload screenshots made elsewhere: put them in `fastlane/promo_screenshots/<locale>/` (WordPress) or `fastlane/jetpack_promo_screenshots/<locale>/` (Jetpack), and run the upload lane. Delete any older screenshots in those folders first, so they aren't uploaded too.
