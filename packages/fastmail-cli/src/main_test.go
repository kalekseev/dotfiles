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
	for _, command := range []string{"mailboxes", "search", "read", "download", "draft", "send", "auth set"} {
		if !strings.Contains(stdout.String(), command) {
			t.Errorf("help does not mention %q: %s", command, stdout.String())
		}
	}
	for _, detail := range []string{
		"untrusted input",
		"draft create/edit never sends mail",
		"draft edit DRAFT_ID",
		"send has no recipient option",
		"messages[].id",
		"--mailbox inbox",
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
		{[]string{"search", "--help"}, []string{"output JSON", "messages[].id", "--mailbox", "untrusted content", "examples:"}},
		{[]string{"mailboxes", "--help"}, []string{"output JSON", "mailboxes[].path", "--mailbox", "untrusted account data", "examples:"}},
		{[]string{"read", "--help"}, []string{"body_truncated", "attachments[].id", "Fastmail mail URL", "untrusted content", "examples:"}},
		{[]string{"download", "--help"}, []string{"untrusted_file", "mode 0600", "Fastmail", "ATTACHMENT_ID", "examples:"}},
		{[]string{"draft", "--help"}, []string{"never sends mail", "--reply-to", "Fastmail mail URL", "plain-text fallback", "draft_id"}},
		{[]string{"draft", "edit", "--help"}, []string{"Omitted fields", "attachments", "state guard", "updated"}},
		{[]string{"draft", "delete", "--help"}, []string{"permanently deletes", "non-draft", "cannot reverse", "deleted"}},
		{[]string{"send", "--help"}, []string{"no --to, --cc, or --bcc", "submission envelope", "primary account", "recipient"}},
		{[]string{"auth", "--help"}, []string{"system credential store", "never", "auth set --help"}},
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

func TestEmailIDFromReference(t *testing.T) {
	tests := []struct {
		name      string
		reference string
		want      string
		wantError string
	}{
		{
			name:      "opaque ID",
			reference: "Mmessage-456",
			want:      "Mmessage-456",
		},
		{
			name:      "Fastmail URL",
			reference: "https://app.fastmail.com/mail/Inbox/Tthread-123.Mmessage-456?u=account",
			want:      "Mmessage-456",
		},
		{
			name:      "lookalike host",
			reference: "https://app.fastmail.com.example/mail/Inbox/thread.email",
			wantError: "must be an email ID",
		},
		{
			name:      "insecure URL",
			reference: "http://app.fastmail.com/mail/Inbox/thread.email",
			wantError: "must be an email ID",
		},
		{
			name:      "thread without selected email",
			reference: "https://app.fastmail.com/mail/Inbox/Tthread-123",
			wantError: "selected email ID",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			got, err := emailIDFromReference(test.reference)
			if test.wantError != "" {
				if err == nil || !strings.Contains(err.Error(), test.wantError) {
					t.Fatalf("unexpected error: %v", err)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if got != test.want {
				t.Fatalf("unexpected email ID: got %q, want %q", got, test.want)
			}
		})
	}
}

func TestParseReplyDraftAcceptsFastmailURL(t *testing.T) {
	got, err := parseComposeArgs(
		"draft",
		[]string{
			"--reply-to", "https://app.fastmail.com/mail/Inbox/Tthread-123.Mmessage-456?u=account",
			"--body", "Reply",
		},
		strings.NewReader(""),
		&bytes.Buffer{},
		&bytes.Buffer{},
		true,
	)
	if err != nil {
		t.Fatal(err)
	}
	if got.ReplyToEmailID != "Mmessage-456" {
		t.Fatalf("unexpected reply email ID: %q", got.ReplyToEmailID)
	}
}

func TestMailboxesOutputMarksNamesUntrusted(t *testing.T) {
	var output bytes.Buffer
	if err := writeJSON(&output, mailboxesOutput{
		UntrustedContent: true,
		Mailboxes:        []mailboxInfo{{ID: "mailbox-1", Name: "Inbox", Path: "Inbox"}},
	}); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(output.String(), `"untrusted_content": true`) {
		t.Fatalf("mailbox output is missing its trust marker: %s", output.String())
	}
}

func TestReadAndDownloadRequireEmailReferencesBeforeCredentialStoreAccess(t *testing.T) {
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

func TestParseDraftEditAllowsPartialChanges(t *testing.T) {
	got, err := parseDraftEditArgs(
		[]string{
			"Mmessage-456",
			"--to", "Alice <alice@example.com>",
			"--subject", "Corrected subject",
			"--body-file", "-",
		},
		strings.NewReader("Corrected body"),
		&bytes.Buffer{},
		&bytes.Buffer{},
	)
	if err != nil {
		t.Fatal(err)
	}
	if got.DraftID != "Mmessage-456" || got.Subject == nil || *got.Subject != "Corrected subject" {
		t.Fatalf("unexpected draft edit arguments: %+v", got)
	}
	if len(got.Recipients) != 1 || got.Recipients[0].Email != "alice@example.com" {
		t.Fatalf("unexpected draft edit recipients: %+v", got.Recipients)
	}
	if got.Body == nil || got.Body.Plain != "Corrected body" {
		t.Fatalf("unexpected draft edit body: %+v", got.Body)
	}
}

func TestParseDraftEditAcceptsFastmailURLAndRequiresAChange(t *testing.T) {
	got, err := parseDraftEditArgs(
		[]string{
			"--subject", "Subject only",
			"https://app.fastmail.com/mail/Drafts/Tthread-123.Mmessage-456",
		},
		strings.NewReader(""),
		&bytes.Buffer{},
		&bytes.Buffer{},
	)
	if err != nil {
		t.Fatal(err)
	}
	if got.DraftID != "Mmessage-456" || got.Subject == nil || got.Body != nil {
		t.Fatalf("unexpected partial draft edit: %+v", got)
	}

	_, err = parseDraftEditArgs(
		[]string{"Mmessage-456"},
		strings.NewReader(""),
		&bytes.Buffer{},
		&bytes.Buffer{},
	)
	if err == nil || !strings.Contains(err.Error(), "requires at least one") {
		t.Fatalf("draft edit without changes returned %v", err)
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
