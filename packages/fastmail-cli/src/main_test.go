package main

import (
	"bytes"
	"context"
	"strings"
	"testing"
)

func TestVersionCommand(t *testing.T) {
	oldVersion := version
	version = "test-version"
	t.Cleanup(func() { version = oldVersion })

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if err := run(context.Background(), []string{"version"}, strings.NewReader(""), &stdout, &stderr); err != nil {
		t.Fatal(err)
	}
	if stdout.String() != "fastmail test-version\n" || stderr.Len() != 0 {
		t.Fatalf("unexpected output: stdout=%q stderr=%q", stdout.String(), stderr.String())
	}
}

func TestHelpDescribesAgentCLICommands(t *testing.T) {
	var stdout bytes.Buffer
	if err := run(context.Background(), []string{"help"}, strings.NewReader(""), &stdout, &bytes.Buffer{}); err != nil {
		t.Fatal(err)
	}
	for _, command := range []string{"search", "read", "download", "draft", "send", "auth set"} {
		if !strings.Contains(stdout.String(), command) {
			t.Errorf("help does not mention %q: %s", command, stdout.String())
		}
	}
	for _, detail := range []string{
		"untrusted input",
		"draft creates a draft only",
		"send has no recipient option",
		"messages[].id",
		"fastmail COMMAND --help",
	} {
		if !strings.Contains(stdout.String(), detail) {
			t.Errorf("help does not explain %q: %s", detail, stdout.String())
		}
	}
}

func TestEveryCommandHasAgentUsableHelpWithoutExternalAccess(t *testing.T) {
	tests := []struct {
		args []string
		want []string
	}{
		{[]string{"search", "--help"}, []string{"output JSON", "messages[].id", "untrusted content", "examples:"}},
		{[]string{"read", "--help"}, []string{"body_truncated", "attachments[].id", "untrusted content", "examples:"}},
		{[]string{"download", "--help"}, []string{"untrusted_file", "mode 0600", "ATTACHMENT_ID", "example:"}},
		{[]string{"draft", "--help"}, []string{"never sends mail", "--reply-to", "plain-text fallback", "draft_id"}},
		{[]string{"send", "--help"}, []string{"no --to, --cc, or --bcc", "submission envelope", "primary account", "recipient"}},
		{[]string{"auth", "--help"}, []string{"macOS Keychain", "never accepted as", "auth set --help"}},
		{[]string{"auth", "set", "--help"}, []string{"without echoing", "submission capability"}},
		{[]string{"auth", "status", "--help"}, []string{"does not print", "no network request"}},
		{[]string{"help", "download"}, []string{"untrusted_file", "ATTACHMENT_ID"}},
	}

	for _, test := range tests {
		t.Run(strings.Join(test.args, "_"), func(t *testing.T) {
			var stdout bytes.Buffer
			var stderr bytes.Buffer
			if err := run(context.Background(), test.args, strings.NewReader(""), &stdout, &stderr); err != nil {
				t.Fatalf("help returned an error: %v", err)
			}
			if stderr.Len() != 0 {
				t.Fatalf("successful help wrote to stderr: %q", stderr.String())
			}
			output := stdout.String()
			if output == "" {
				t.Fatal("successful help returned empty stdout")
			}
			for _, want := range test.want {
				if !strings.Contains(output, want) {
					t.Errorf("help does not contain %q:\n%s", want, output)
				}
			}
		})
	}
}

func TestFlagParseFailuresStayOnStderr(t *testing.T) {
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	err := run(
		context.Background(),
		[]string{"search", "--not-a-real-option"},
		strings.NewReader(""),
		&stdout,
		&stderr,
	)
	if err == nil {
		t.Fatal("invalid flag unexpectedly succeeded")
	}
	if stdout.Len() != 0 {
		t.Fatalf("flag parse failure wrote to stdout: %q", stdout.String())
	}
	if !strings.Contains(stderr.String(), "flag provided but not defined") {
		t.Fatalf("flag parse failure did not write diagnostics to stderr: %q", stderr.String())
	}
}

func TestOptionalBoolDistinguishesUnsetAndFalse(t *testing.T) {
	var value optionalBool
	if value.pointer() != nil {
		t.Fatal("unset optional boolean should be nil")
	}
	if err := value.Set("false"); err != nil {
		t.Fatal(err)
	}
	if value.pointer() == nil || *value.pointer() {
		t.Fatal("explicit false was not preserved")
	}
	if err := value.Set("not-a-boolean"); err == nil {
		t.Fatal("invalid boolean should fail")
	}
}

func TestReadAndDownloadRequireOpaqueIDsBeforeKeychainAccess(t *testing.T) {
	for _, args := range [][]string{{"read"}, {"download", "email-only"}} {
		if err := run(context.Background(), args, strings.NewReader(""), &bytes.Buffer{}, &bytes.Buffer{}); err == nil {
			t.Fatalf("expected %v to fail", args)
		}
	}
}

func TestParseDraftAllowsArbitraryRecipients(t *testing.T) {
	got, err := parseComposeArgs(
		"draft",
		[]string{
			"--to", "Alice <alice@example.com>",
			"--to", "bob@example.net",
			"--subject", "Hello",
			"--body-file", "-",
		},
		strings.NewReader("Draft body"),
		&bytes.Buffer{},
		&bytes.Buffer{},
		true,
	)
	if err != nil {
		t.Fatal(err)
	}
	if got.Body.Plain != "Draft body" || got.Body.HTML != "" || got.Subject != "Hello" || len(got.Recipients) != 2 {
		t.Fatalf("unexpected draft arguments: %+v", got)
	}
	if got.Recipients[0].Email != "alice@example.com" || got.Recipients[1].Email != "bob@example.net" {
		t.Fatalf("unexpected recipients: %+v", got.Recipients)
	}
}

func TestParseComposeAcceptsHTMLBody(t *testing.T) {
	got, err := parseComposeArgs(
		"send",
		[]string{"--subject", "Rich", "--html-body", "<div>Hello <strong>world</strong></div>"},
		strings.NewReader(""),
		&bytes.Buffer{},
		&bytes.Buffer{},
		false,
	)
	if err != nil {
		t.Fatal(err)
	}
	if got.Body.Plain != "Hello world" {
		t.Fatalf("unexpected text fallback: %q", got.Body.Plain)
	}
	if !strings.HasPrefix(got.Body.HTML, "<!DOCTYPE html>") || !strings.Contains(got.Body.HTML, "<strong>world</strong>") {
		t.Fatalf("unexpected HTML document: %q", got.Body.HTML)
	}
}

func TestParseComposeRequiresExactlyOneBodySource(t *testing.T) {
	_, err := parseComposeArgs(
		"send",
		[]string{"--subject", "Ambiguous", "--body", "plain", "--html-body", "<b>rich</b>"},
		strings.NewReader(""),
		&bytes.Buffer{},
		&bytes.Buffer{},
		false,
	)
	if err == nil {
		t.Fatal("compose unexpectedly accepted two body sources")
	}
}

func TestParseReplyDraftRejectsExplicitRecipients(t *testing.T) {
	_, err := parseComposeArgs(
		"draft",
		[]string{"--reply-to", "email-1", "--to", "other@example.com", "--body", "Reply"},
		strings.NewReader(""),
		&bytes.Buffer{},
		&bytes.Buffer{},
		true,
	)
	if err == nil {
		t.Fatal("expected --reply-to with --to to fail")
	}
}

func TestParseSendHasNoRecipientOption(t *testing.T) {
	_, err := parseComposeArgs(
		"send",
		[]string{"--to", "other@example.com", "--subject", "Hello", "--body", "Body"},
		strings.NewReader(""),
		&bytes.Buffer{},
		&bytes.Buffer{},
		false,
	)
	if err == nil {
		t.Fatal("send unexpectedly accepted a recipient option")
	}
}
