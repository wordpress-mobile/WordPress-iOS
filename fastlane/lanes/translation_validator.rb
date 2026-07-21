# frozen_string_literal: true

# Format-specifier safety gate for machine-translated strings.
#
# The one correctness invariant for a translated `.strings` / `.xcstrings` value: it must preserve the
# source's printf / NSString format ARGUMENTS exactly — same count, same types, and the same index→type
# mapping (bare specifiers are numbered by appearance order, so a translation may reorder them with
# explicit `%2$@ … %1$@` specifiers — the standard iOS mechanism). The surrounding prose is free to
# change; the argument contract is not. Break it and the app reads the wrong vararg off the stack — a
# crash or garbage at runtime, in a locale the author can't read and CI can't catch.
#
# This is deliberately plain Ruby with no dependencies, so it can gate EVERY machine translation before it
# is written and be unit-tested directly. It's the floor under the `human ?? AI ?? English` resolution in
# `PluralStrings.fold_cell`: an AI cell that fails this check is discarded (the caller falls through to the
# English source, flagged needs_review) rather than shipped.
module TranslationValidator
  module_function

  # printf / NSString format specifier: optional positional `N$`, flags, width, precision, length modifier,
  # conversion. The space flag (`% d`) is deliberately EXCLUDED — exactly as `CatalogHelper::FORMAT_SPECIFIER`
  # excludes it — because `% <letter>` matches inside ordinary prose ("100% done" → "% d"), which would make
  # the validator hallucinate an argument in plain text and reject a perfectly good translation.
  FORMAT_SPECIFIER = /
    %                                    # leading percent
    (?:(?<position>\d+)\$)?              # optional positional index: 1$, 2$, …
    [\#0\-+']*                           # flags (NOT space — see note above)
    (?<width>\d+|\*)?                    # field width (`*` = a dynamic-width int argument)
    (?:\.(?<precision>\d+|\*))?          # precision (`*` = a dynamic-precision int argument)
    (?<length>hh|h|ll|l|L|q|z|t|j)?      # length modifier
    (?<conv>[@dDiuUxXoOfFeEgGaAcCsSpn%]) # conversion
  /x

  # Conversion char → coarse argument type-class. We compare by class, not by exact letter, so cosmetic
  # swaps that don't change the consumed argument (`%x`↔`%X`, `%d`↔`%i`) pass, while a real type change
  # that WOULD crash (`%@`→`%d`: object vs integer) is caught. The length modifier is kept separately in the
  # signature, because `%d`↔`%ld` is a genuine ABI difference (int vs long) that can crash on mismatch.
  TYPE_CLASS = {
    '@' => :object,
    'd' => :int, 'D' => :int, 'i' => :int, 'u' => :int, 'U' => :int,
    'x' => :int, 'X' => :int, 'o' => :int, 'O' => :int,
    'f' => :float, 'F' => :float, 'e' => :float, 'E' => :float,
    'g' => :float, 'G' => :float, 'a' => :float, 'A' => :float,
    's' => :cstring, 'S' => :cstring, 'c' => :char, 'C' => :char, 'p' => :pointer
  }.freeze
  private_constant :TYPE_CLASS

  # Two parallel views of a string's format arguments:
  #   positional — { index => "length:type-class" }; order-INDEPENDENT (reordering `%1$@`/`%2$@` to suit
  #                target grammar is the whole point of positional specifiers).
  #   sequential — [ "length:type-class", … ]; order-DEPENDENT (a non-positional specifier's argument is
  #                bound by appearance order, so `%@ %d` and `%d %@` are NOT interchangeable).
  # `%%` (a literal percent) consumes no argument and is excluded from both.
  Signature = Struct.new(:positional, :sequential)
  private_constant :Signature

  # True when `candidate` preserves `source`'s format-argument contract.
  def placeholders_match?(source, candidate)
    mismatch_reason(source, candidate).nil?
  end

  # nil when the contract is preserved; otherwise a short human-readable reason (for logging which AI cells
  # were rejected and why).
  def mismatch_reason(source, candidate)
    src = implied_positional(signature(source))
    cand = implied_positional(signature(candidate))

    if src.positional != cand.positional
      "positional placeholders differ (source: #{describe_positional(src.positional)}; " \
        "translation: #{describe_positional(cand.positional)})"
    elsif src.sequential != cand.sequential
      "sequential placeholders differ (source: #{src.sequential.inspect}; translation: #{cand.sequential.inspect})"
    end
  end

  # Parsed argument signature of `str` (see the Signature struct above).
  def signature(str)
    positional = {}
    sequential = []
    each_specifier(str.to_s) { |match| record_specifier(match, positional, sequential) }
    Signature.new(positional, sequential)
  end

  # Fold one matched specifier into the running positional/sequential views (mutated in place). `%%` is a literal
  # percent, consuming no argument. Dynamic field width/precision each consume their OWN int argument, bound
  # sequentially before the value (`%*d` = width int then value; `%.*f` = precision int then value), so counting
  # them keeps `%d` and `%*d` — which are NOT interchangeable — from reducing to the same signature.
  def record_specifier(match, positional, sequential)
    return if match[:conv] == '%'

    sequential << ':int' if match[:width] == '*'
    sequential << ':int' if match[:precision] == '*'

    token = "#{match[:length]}:#{TYPE_CLASS.fetch(match[:conv], match[:conv])}"
    if match[:position]
      add_positional(positional, match[:position].to_i, token)
    else
      sequential << token
    end
  end
  private_class_method :record_specifier

  # Record a positional specifier's type at its index. A positional index MAY be referenced more than once, but only
  # with a CONSISTENT type (`%1$d … %1$d` is legal — it reads argument 1 twice). Two different types at one index is
  # malformed — it passes an int to a `%@` conversion (or vice versa) at runtime — so store the conflict as a
  # distinct token that can never equal a well-formed source's single type, rather than overwriting last-wins.
  def add_positional(positional, index, token)
    existing = positional[index]
    positional[index] = existing && existing != token ? "conflict(#{[existing, token].sort.join(', ')})" : token
  end
  private_class_method :add_positional

  # A purely-sequential signature rewritten with the implicit 1..N indices its bare specifiers already
  # carry (`%@ %d` binds argument 1 then 2, so it becomes `{1 => object, 2 => int}`). This is what lets a
  # translation reorder a NON-positional source via explicit positional specifiers: once both sides are
  # expressed as index→type maps, `%@ - %@` and `%2$@ - %1$@` compare equal — the reorder is honored at
  # runtime by `String(format:)` regardless of the source's shape. A genuine sequential flip still fails,
  # because `%@: %d` → `{1 => object, 2 => int}` and `%d : %@` → `{1 => int, 2 => object}` disagree on
  # which index owns which type. A signature that already uses positional specifiers is returned
  # unchanged; so is one that MIXES bare and positional specifiers (malformed per Apple's docs), so a
  # mixed string still requires an exact structural match and can't accidentally validate against a clean
  # map.
  def implied_positional(sig)
    return sig unless sig.positional.empty? && !sig.sequential.empty?

    positional = {}
    sig.sequential.each_with_index { |token, i| positional[i + 1] = token }
    Signature.new(positional, [])
  end
  private_class_method :implied_positional

  # Yields each format-specifier MatchData in appearance order. Scans forward from the end of each match, so
  # adjacent specifiers (`%d%@`) and specifiers embedded in text are all found.
  def each_specifier(str)
    pos = 0
    while (match = FORMAT_SPECIFIER.match(str, pos))
      yield match
      pos = match.end(0)
    end
  end
  private_class_method :each_specifier

  def describe_positional(positional)
    return 'none' if positional.empty?

    positional.sort.map { |index, token| "%#{index}$(#{token})" }.join(', ')
  end
  private_class_method :describe_positional
end
