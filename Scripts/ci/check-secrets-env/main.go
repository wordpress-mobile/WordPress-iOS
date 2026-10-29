// Finds why the S3 secrets hook can't parse an env file, without printing any
// secret. Uses the same parser and version as elastic-ci-stack-s3-secrets-hooks
// v2.8.0 (github.com/joho/godotenv v1.5.1).
//
// Reads the file on stdin. Prints only line numbers, variable names and the
// shape of each line, never a value and never godotenv's error text (which
// can quote the file).
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

var assignment = regexp.MustCompile(`^\s*(export\s+)?([A-Za-z_][A-Za-z0-9_.]*)\s*=`)

func parses(lines []string) bool {
	_, err := godotenv.UnmarshalBytes([]byte(strings.Join(lines, "\n") + "\n"))
	return err == nil
}

// shape describes a line without revealing its value.
func shape(line string) string {
	trimmed := strings.TrimSpace(line)
	switch {
	case trimmed == "":
		return "blank"
	case strings.HasPrefix(trimmed, "#"):
		return "comment"
	}
	if m := assignment.FindStringSubmatch(line); m != nil {
		value := strings.TrimSpace(line[len(m[0]):])
		notes := []string{}
		if m[1] != "" {
			notes = append(notes, "export")
		}
		if strings.Contains(line[:len(m[0])], " =") || strings.HasPrefix(line[len(m[0]):], " ") {
			notes = append(notes, "space around =")
		}
		switch {
		case value == "":
			notes = append(notes, "empty value")
		case value[0] == '"' || value[0] == '\'' || value[0] == '`':
			q := value[0]
			if strings.Count(value, string(q)) < 2 {
				notes = append(notes, fmt.Sprintf("opens a %c-quoted value that doesn't close on this line", q))
			} else {
				notes = append(notes, fmt.Sprintf("%c-quoted value", q))
			}
		default:
			notes = append(notes, "unquoted value")
		}
		if strings.Contains(value, "$(") || strings.Contains(value, "`") {
			notes = append(notes, "contains command substitution")
		}
		return fmt.Sprintf("%s (%s, %d chars)", m[2], strings.Join(notes, ", "), len(value))
	}
	if m := regexp.MustCompile(`^\s*(export\s+)?([^=\s"']+)\s*=`).FindStringSubmatch(line); m != nil && len(m[2]) <= 64 {
		return fmt.Sprintf("assigns to %q, a name godotenv rejects (only letters, digits, _ and . are allowed)", m[2])
	}
	first := strings.Fields(trimmed)[0]
	if regexp.MustCompile(`^[A-Za-z_][A-Za-z0-9_-]*$`).MatchString(first) && len(first) <= 12 {
		// Likely a shell keyword or command (if, fi, source, ...): safe to name.
		return fmt.Sprintf("not an assignment; starts with the word %q (%d chars)", first, len(trimmed))
	}
	return fmt.Sprintf("not an assignment (%d chars; maybe the continuation of a multi-line value)", len(trimmed))
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
	from := culprit - 3
	if from < 1 {
		from = 1
	}
	for i := from; i <= culprit+1 && i <= len(lines); i++ {
		marker := "  "
		if i == culprit {
			marker = "→ "
		}
		fmt.Printf("%sline %d: %s\n", marker, i, shape(lines[i-1]))
	}
}
