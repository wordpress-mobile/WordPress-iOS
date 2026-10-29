// Finds why the S3 secrets hook can't parse an env file, without printing any
// secret. Uses the same parser and version as elastic-ci-stack-s3-secrets-hooks
// v2.8.0 (github.com/joho/godotenv v1.5.1).
//
// Reads the file on stdin. Prints only line numbers, upper-case variable names
// of plain assignments, and each other line's length and character kinds:
// never a value, never text from a line that could be part of one, and never
// godotenv's error text (which can quote the file).
package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"regexp"
	"strings"

	"github.com/joho/godotenv"
)

// Only a line that is a plain assignment to an upper-case name is described by
// name. Anything else could be part of a secret value, so it is described only
// by its length and the kinds of characters in it, never by its text.
var assignment = regexp.MustCompile(`^\s*(export\s+)?([A-Z][A-Z0-9_]*)\s*=`)

// Shell words that would explain why bash accepts a line godotenv rejects. A
// line's first word is printed only if it is one of these fixed strings.
var shellWords = map[string]bool{
	"if": true, "then": true, "else": true, "elif": true, "fi": true, "for": true, "do": true,
	"done": true, "while": true, "case": true, "esac": true, "source": true, ".": true,
	"read": true, "cat": true, "declare": true, "typeset": true, "local": true, "readonly": true,
	"set": true, "unset": true, "function": true, "printf": true, "echo": true, "export": true,
	"EOF": true, "END": true, "KEY": true,
}

func parses(lines []string) bool {
	_, err := godotenv.UnmarshalBytes([]byte(strings.Join(lines, "\n") + "\n"))
	return err == nil
}

// openQuote reports the quote character a line leaves open, if any.
func openQuote(text string, open byte) byte {
	for i := 0; i < len(text); i++ {
		c := text[i]
		if c == '\\' && open != '\'' {
			i++
			continue
		}
		switch {
		case open == 0 && (c == '"' || c == '\'' || c == '`'):
			open = c
		case open != 0 && c == open:
			open = 0
		}
	}
	return open
}

// classes describes the kinds of characters in a line, without its text.
func classes(text string) string {
	var kinds []string
	has := func(f func(rune) bool) bool { return strings.IndexFunc(text, f) >= 0 }
	if has(func(r rune) bool { return r >= 'A' && r <= 'Z' }) {
		kinds = append(kinds, "upper")
	}
	if has(func(r rune) bool { return r >= 'a' && r <= 'z' }) {
		kinds = append(kinds, "lower")
	}
	if has(func(r rune) bool { return r >= '0' && r <= '9' }) {
		kinds = append(kinds, "digits")
	}
	for _, c := range []string{"=", "\"", "'", "`", "$", "(", "<<", "\\", " ", "-", "+", "/", "#", "{", ":"} {
		if strings.Contains(text, c) {
			kinds = append(kinds, fmt.Sprintf("%q", c))
		}
	}
	return strings.Join(kinds, " ")
}

// describe returns a description of every line, tracking multi-line quoted values.
func describe(lines []string) []string {
	out := make([]string, len(lines))
	var open byte
	heredoc := ""
	heredocStart := regexp.MustCompile(`<<-?\s*['"]?([A-Za-z_][A-Za-z0-9_]*)['"]?`)
	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		if heredoc != "" {
			if trimmed == heredoc {
				out[i] = "the end of the heredoc"
				heredoc = ""
			} else {
				out[i] = fmt.Sprintf("inside a heredoc that started earlier (%d chars)", len(trimmed))
			}
			continue
		}
		if m := heredocStart.FindStringSubmatch(line); m != nil {
			heredoc = m[1]
		}
		inside := open != 0
		switch {
		case inside:
			out[i] = fmt.Sprintf("inside a %c-quoted value that started earlier (%d chars)", open, len(trimmed))
			open = openQuote(line, open)
			if open == 0 {
				out[i] += "; the value closes here"
			}
			continue
		case trimmed == "":
			out[i] = "blank"
			continue
		case strings.HasPrefix(trimmed, "#"):
			out[i] = "comment"
			continue
		}
		if m := assignment.FindStringSubmatch(line); m != nil {
			value := strings.TrimSpace(line[len(m[0]):])
			notes := []string{}
			if m[1] != "" {
				notes = append(notes, "export")
			}
			open = openQuote(value, 0)
			switch {
			case value == "":
				notes = append(notes, "empty value")
			case open != 0:
				notes = append(notes, fmt.Sprintf("opens a %c-quoted value that doesn't close on this line", open))
			case value[0] == '"' || value[0] == '\'' || value[0] == '`':
				notes = append(notes, fmt.Sprintf("%c-quoted value", value[0]))
			default:
				notes = append(notes, "unquoted value")
			}
			if strings.Contains(value, "$(") || strings.Contains(value, "<<") {
				notes = append(notes, "uses shell syntax ($( or <<)")
			}
			name := m[2]
			if !strings.Contains(name, "_") {
				// A short all-capitals base64 line ending in `=` looks like this too.
				name = fmt.Sprintf("an upper-case name without an underscore (%d chars)", len(name))
			}
			out[i] = fmt.Sprintf("%s (%s, %d chars)", name, strings.Join(notes, ", "), len(value))
			continue
		}
		first := strings.Fields(trimmed)[0]
		word := ""
		if shellWords[first] {
			word = fmt.Sprintf("; starts with the shell word %q", first)
		} else if strings.HasPrefix(trimmed, "-----BEGIN") || strings.HasPrefix(trimmed, "-----END") {
			word = "; looks like a PEM BEGIN/END line"
		}
		out[i] = fmt.Sprintf("not a NAME=value line (%d chars; has %s)%s", len(trimmed), classes(trimmed), word)
		open = openQuote(line, 0)
		if open != 0 {
			out[i] += fmt.Sprintf("; leaves a %c quote open", open)
		}
	}
	return out
}

func main() {
	raw, err := io.ReadAll(os.Stdin)
	if err != nil || len(raw) == 0 {
		fmt.Fprintln(os.Stderr, "usage: <env file> | go run .")
		os.Exit(2)
	}
	lines := strings.Split(strings.TrimRight(string(bytes.ReplaceAll(raw, []byte("\r\n"), []byte("\n"))), "\n"), "\n")
	if bytes.Contains(raw, []byte("\r")) {
		fmt.Println("Note: the file contains carriage returns (Windows line endings).")
	}
	if parses(lines) {
		fmt.Printf("Parses fine (%d lines).\n", len(lines))
		return
	}

	// The first line from which every longer prefix fails. A multi-line value
	// cut in half fails too, so a single failing prefix isn't enough.
	culprit := len(lines)
	for n := len(lines); n >= 1; n-- {
		if parses(lines[:n]) {
			break
		}
		culprit = n
	}
	fmt.Printf("Fails to parse. The first line it can't get past is line %d of %d.\n\n", culprit, len(lines))
	descriptions := describe(lines)
	from := culprit - 2
	if from < 1 {
		from = 1
	}
	for i := from; i <= culprit+6 && i <= len(lines); i++ {
		marker := "  "
		if i == culprit {
			marker = "→ "
		}
		fmt.Printf("%sline %d: %s\n", marker, i, descriptions[i-1])
	}
}
