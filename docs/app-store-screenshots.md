# App Store Screenshots

The Jetpack app's App Store screenshots are made from the app itself, in every language the App Store listing is translated into. Making them takes three `fastlane` lanes:

1. [`jetpack_screenshots`](#taking-the-screenshots) takes the raw screenshots.
2. [`create_jetpack_promo_screenshots`](#composing-the-screenshots) adds a headline above each one and sets it in a device frame.
3. [`update_jetpack_metadata_on_app_store_connect with_screenshots:true`](#uploading-the-screenshots) uploads them.

The WordPress app's screenshots are still composed the old way, from raw screenshots taken by hand: see [The WordPress app](#the-wordpress-app).

## Taking the screenshots

```bash
bundle exec fastlane jetpack_screenshots
```

This builds the Jetpack app with the [HTTP fixtures](ui-tests.md#fixtures) compiled in, then runs the `AppStoreScreenshots` UI test once for each device and language. Each run saves its screenshots to `fastlane/jetpack_screenshots/<locale>/`.

The test runs against the fixtures, so every screenshot shows the same account and content, and nothing reaches WordPress.com. It finds its way around by accessibility identifiers and the fixtures' content, never by the app's own text, so it works in every language.

| | Device | Size |
|---|---|---|
| iPhone | iPhone 18 Pro Max | 1320 × 2868 (6.9") |
| iPad | iPad Pro 13-inch (M5) | 2064 × 2752 (13") |
| iPhone Duo | iPhone Duo | 1398 × 2034 (outer display) and 2007 × 2853 (inner display) |

Each device gets a simulator of its own, called "Screenshots iPhone 18 Pro Max" and so on, which the lane creates the first time. It sets the simulator to light mode and its status bar to 9:41 with full signal and battery.

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

### Translating what's on screen

The app's own text is in each language already. The content (post titles, the draft in the editor, the Reader post, notifications) comes from the fixtures, which are in English, so it's translated separately:

- `fastlane/appstoreres/jetpack_screenshot_content/en.json` lists that content by key, exactly as it reads in the fixtures, HTML and curly quotes included.
- `<locale>.json` beside it has the translations, by the same keys. A key it leaves out stays in English, and the lane says which.

For each language with a translation, the lane writes a copy of every fixture file that has content to translate, with it translated, and the app loads those over the fixtures (the `-ui-test-http-fixtures-overlay` launch argument). The fixtures the UI tests assert on don't change. `fastlane/lanes/screenshot_content_helper.rb` does the translating:

- An entry of a few words or more is replaced wherever it appears, such as a paragraph inside a post. A shorter one, such as a post called "Home", only replaces a value that's exactly that, so it can't change a word inside other text. To translate a short heading inside HTML, include its tag in the entry, as `<strong>How to book</strong>` does.
- Notifications mark names and post titles in their text. A translation has to keep each of those, exactly as it's translated on its own, or the lane stops and says which.

To add content, find the screen's text in `Tests/JetpackUITests/Fixtures`, add it to `en.json` exactly as it is there, and add its translations.

### Changing what's on screen

The screens are in `Tests/JetpackUITests/Screenshots/AppStoreScreenshots.swift`, numbered in the order they appear in the App Store. The content comes from the fixtures in `Tests/JetpackUITests/Fixtures`, which [docs/ui-tests.md](ui-tests.md#fixtures) describes. Images are served from `Fixtures/__files`: the avatars there are generated placeholders, not anyone's Gravatar.

The test is skipped in an ordinary run of the UI tests, because only the lane tells it where to save the screenshots.

## Composing the screenshots

```bash
bundle exec fastlane create_jetpack_promo_screenshots
```

This runs `Scripts/app-store-screenshots/compose.swift`, which writes the final screenshots to `fastlane/jetpack_promo_screenshots/<locale>/`, ready to upload. Each language gets a title screen with the WordPress and Jetpack logos, then each raw screenshot with its headline above it, in a device frame.

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

The English is in `fastlane/appstoreres/jetpack_metadata/source/`, and each translation in the folder for its locale. To change them:

1. Edit the files in `source`, and copy them to `en-US`.
2. The release process uploads them to GlotPress at code freeze, with the rest of the App Store strings (`update_appstore_strings`).
3. Once they're translated, run `bundle exec fastlane download_jetpack_promo_strings` to download them.

A language without all of its headlines is left out of the final screenshots, and the App Store shows the English screenshots there instead. That's better than an English headline over a translated app.

## Uploading the screenshots

Once the final screenshots are in `fastlane/jetpack_promo_screenshots/<locale>/`:

```bash
bundle exec fastlane update_jetpack_metadata_on_app_store_connect with_screenshots:true
```

The App Store tells which device a screenshot is for by its size, and orders a device's screenshots by file name. Each run's log and result bundle are in `build/results/screenshots/`.

> [!NOTE]
> This uploads the app's other App Store metadata too: its name, subtitle, description and so on.

## The WordPress app

The WordPress app's screenshots are composed by the release toolkit's `promo_screenshots` action, from raw screenshots in `fastlane/screenshots/` and the layout in `fastlane/screenshots.json`:

```bash
bundle exec fastlane create_promo_screenshots
bundle exec fastlane update_wordpress_metadata_on_app_store_connect with_screenshots:true
```

Its headlines are `fastlane/appstoreres/metadata/<locale>/app_store_screenshot_*.txt`, downloaded from GlotPress with `download_promo_strings`.

### Using screenshots a designer made

Either app can instead upload screenshots made elsewhere: put them in `fastlane/promo_screenshots/<locale>/` (WordPress) or `fastlane/jetpack_promo_screenshots/<locale>/` (Jetpack), and run the upload lane. Delete any older screenshots in those folders first, so they aren't uploaded too.
