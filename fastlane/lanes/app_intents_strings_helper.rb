# frozen_string_literal: true

# Logic for the App Intents (`LocalizedStringResource`) leg of the GlotPress upload. Plain Ruby with no
# fastlane dependencies, so it's unit-testable directly — the lanes in `localization_catalog.rb` call into it.
module AppIntentsStrings
  module_function

  # The build-free extraction cannot type interpolations (a defaultValue's `\(…)` segments), so it
  # emits untyped `%arg` placeholders. Rewrite them as positional printf specifiers (`%1$@`, `%2$@`,
  # …), which is what GlotPress translators and the runtime's format-style resolution expect. This is
  # only correct for String-valued interpolations, so App Intents defaultValues must interpolate
  # preformatted Strings, never raw numbers or dates (see docs/localization.md).
  #
  # Two bugs, red in the adjacent suite: the counter advances on placeholders that already carry an explicit
  # position, and an escaped percent before "arg" is consumed as a placeholder.
  def positionalize_untyped_arguments(value)
    index = 0
    value.gsub(/%(\d+\$)?arg/) do
      index += 1
      "%#{Regexp.last_match(1) || "#{index}$"}@"
    end
  end
end
