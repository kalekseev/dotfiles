package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"unicode/utf8"
)

func TestSanitizeFilename(t *testing.T) {
	tests := map[string]string{
		"../../secret.txt":  "secret.txt",
		"..":                "attachment",
		" report:2026.pdf ": "report_2026.pdf",
		"a/b\\c.txt":        "b_c.txt",
	}
	for input, want := range tests {
		if got := sanitizeFilename(input); got != want {
			t.Errorf("sanitizeFilename(%q) = %q, want %q", input, got, want)
		}
	}
}

func TestSanitizeFilenameTruncatesAtUTF8Boundary(t *testing.T) {
	input := "a" + strings.Repeat("é", 100) + ".pdf"
	got := sanitizeFilename(input)
	if !utf8.ValidString(got) {
		t.Fatalf("sanitizeFilename returned invalid UTF-8: %q", got)
	}
	if len(got) > 200 {
		t.Fatalf("sanitizeFilename returned %d bytes, want at most 200", len(got))
	}
	if !strings.HasSuffix(got, ".pdf") {
		t.Fatalf("sanitizeFilename did not preserve extension: %q", got)
	}
}

func TestHostMatchesRequiresDomainBoundary(t *testing.T) {
	for _, host := range []string{"fastmail.com", "api.fastmail.com", "www.fastmailusercontent.com"} {
		suffix := "fastmail.com"
		if strings.HasSuffix(host, "fastmailusercontent.com") {
			suffix = "fastmailusercontent.com"
		}
		if !hostMatches(host, suffix) {
			t.Errorf("expected %q to match %q", host, suffix)
		}
	}
	if hostMatches("fastmail.com.example.org", "fastmail.com") || hostMatches("evilfastmail.com", "fastmail.com") {
		t.Fatal("host allowlist accepted a non-Fastmail domain")
	}
}

func TestNormalizeUTCDate(t *testing.T) {
	got, err := normalizeUTCDate("after", "2026-07-17T12:00:00.123+03:00")
	if err != nil {
		t.Fatal(err)
	}
	if got != "2026-07-17T09:00:00.123Z" {
		t.Fatalf("normalizeUTCDate returned %q", got)
	}
	if _, err := normalizeUTCDate("after", "yesterday"); err == nil {
		t.Fatal("expected invalid date to fail")
	}
}

func TestCollectBodyEnforcesTotalLimitWithoutBreakingUTF8(t *testing.T) {
	body, truncated := collectBody(
		[]jmapPart{{PartID: "one"}, {PartID: "two"}},
		map[string]bodyValue{
			"one": {Value: "1234"},
			"two": {Value: "é5678"},
		},
		7,
	)
	if body != "1234\n\n" || !truncated || !utf8.ValidString(body) {
		t.Fatalf("unexpected limited body: %q truncated=%v", body, truncated)
	}
}

func TestSelectBodyDistinguishesEmptyPartsFromMissingFormats(t *testing.T) {
	email := jmapEmail{
		TextBody: []jmapPart{{PartID: "empty-text"}},
		HTMLBody: []jmapPart{{PartID: "empty-html"}},
		BodyValues: map[string]bodyValue{
			"empty-text": {Value: ""},
			"empty-html": {Value: ""},
		},
	}
	for _, format := range []string{"text", "html"} {
		bodyType, body, truncated, err := selectBody(email, format, 1024)
		if err != nil {
			t.Fatalf("empty %s part was rejected: %v", format, err)
		}
		if body != "" || truncated {
			t.Fatalf("empty %s part returned body=%q truncated=%v", format, body, truncated)
		}
		want := "text/plain"
		if format == "html" {
			want = "text/html"
		}
		if bodyType != want {
			t.Fatalf("empty %s part returned type %q, want %q", format, bodyType, want)
		}
	}

	if _, _, _, err := selectBody(jmapEmail{}, "text", 1024); err == nil {
		t.Fatal("missing plain-text format was accepted")
	}
	if _, _, _, err := selectBody(jmapEmail{}, "html", 1024); err == nil {
		t.Fatal("missing HTML format was accepted")
	}
}

func TestJMAPClientDoesNotFollowRedirectsWithBearerToken(t *testing.T) {
	targetHit := false
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		targetHit = true
		w.WriteHeader(http.StatusOK)
	}))
	defer target.Close()

	redirect := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, target.URL, http.StatusFound)
	}))
	defer redirect.Close()

	client := newJMAPClient("secret", t.TempDir())
	client.sessionURL = redirect.URL
	client.allowTestServer = true
	if _, err := client.getSession(context.Background()); err == nil {
		t.Fatal("expected redirected JMAP session request to fail")
	}
	if targetHit {
		t.Fatal("bearer-authenticated request followed a redirect")
	}
}

func TestSearchSendsNormalizedUTCDateFilter(t *testing.T) {
	receivedAfter := make(chan string, 1)
	receivedNotKeyword := make(chan string, 1)
	var server *httptest.Server
	server = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/session":
			writeTestJSON(t, w, map[string]any{
				"apiUrl":          server.URL + "/api",
				"downloadUrl":     server.URL + "/download/{accountId}/{blobId}/{name}?type={type}",
				"primaryAccounts": map[string]string{mailCapability: "account-1"},
			})
		case "/api":
			var request struct {
				MethodCalls []json.RawMessage `json:"methodCalls"`
			}
			if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
				t.Error(err)
				return
			}
			var tuple []json.RawMessage
			if err := json.Unmarshal(request.MethodCalls[0], &tuple); err != nil {
				t.Error(err)
				return
			}
			var arguments struct {
				Filter searchFilter `json:"filter"`
			}
			if err := json.Unmarshal(tuple[1], &arguments); err != nil {
				t.Error(err)
				return
			}
			receivedAfter <- arguments.Filter.After
			receivedNotKeyword <- arguments.Filter.NotKeyword
			writeTestJSON(t, w, map[string]any{"methodResponses": []any{
				[]any{"Email/query", map[string]any{"ids": []string{}, "position": 0, "total": 0}, "query"},
			}})
		default:
			http.NotFound(w, r)
		}
	}))
	defer server.Close()

	client := newJMAPClient("test-token", t.TempDir())
	client.sessionURL = server.URL + "/session"
	client.allowTestServer = true
	client.httpClient = server.Client()
	if _, _, err := client.search(context.Background(), searchOptions{
		Filter: searchFilter{
			After:      "2026-07-17T12:00:00+03:00",
			NotKeyword: "$seen",
		},
		Limit: 1,
	}); err != nil {
		t.Fatal(err)
	}
	if got := <-receivedAfter; got != "2026-07-17T09:00:00Z" {
		t.Fatalf("JMAP filter used %q, want UTCDate", got)
	}
	if got := <-receivedNotKeyword; got != "$seen" {
		t.Fatalf("JMAP filter used notKeyword %q, want $seen", got)
	}
}

func TestSearchReadAndDownload(t *testing.T) {
	token := "test-token"
	downloadDir := t.TempDir()
	var server *httptest.Server
	server = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer "+token {
			http.Error(w, "unauthorized", http.StatusUnauthorized)
			return
		}
		switch r.URL.Path {
		case "/session":
			writeTestJSON(t, w, map[string]any{
				"apiUrl":          server.URL + "/api",
				"downloadUrl":     server.URL + "/download/{accountId}/{blobId}/{name}?type={type}",
				"primaryAccounts": map[string]string{mailCapability: "account-1"},
			})
		case "/api":
			var request struct {
				MethodCalls []json.RawMessage `json:"methodCalls"`
			}
			if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
				t.Fatal(err)
			}
			var tuple []json.RawMessage
			if err := json.Unmarshal(request.MethodCalls[0], &tuple); err != nil {
				t.Fatal(err)
			}
			var name string
			_ = json.Unmarshal(tuple[0], &name)
			switch name {
			case "Email/query":
				writeTestJSON(t, w, map[string]any{"methodResponses": []any{
					[]any{"Email/query", map[string]any{"ids": []string{"email-1"}, "position": 0, "total": 1}, "query"},
				}})
			case "Email/get":
				writeTestJSON(t, w, map[string]any{"methodResponses": []any{
					[]any{"Email/get", map[string]any{"list": []any{sampleEmail()}}, "get"},
				}})
			default:
				t.Fatalf("unexpected method %q", name)
			}
		case "/download/account-1/blob-1/report.pdf":
			_, _ = w.Write([]byte("attachment data"))
		default:
			http.NotFound(w, r)
		}
	}))
	defer server.Close()

	client := newJMAPClient(token, downloadDir)
	client.sessionURL = server.URL + "/session"
	client.allowTestServer = true
	client.httpClient = server.Client()

	messages, total, err := client.search(context.Background(), searchOptions{Limit: 5})
	if err != nil {
		t.Fatal(err)
	}
	if total != 1 || len(messages) != 1 || messages[0].Attachments[0].ID != "blob-1" {
		t.Fatalf("unexpected search result: total=%d messages=%+v", total, messages)
	}

	message, err := client.read(context.Background(), "email-1")
	if err != nil {
		t.Fatal(err)
	}
	if message.Body != "Hello from Fastmail" || message.BodyType != "text/plain" {
		t.Fatalf("unexpected message: %+v", message)
	}
	htmlMessage, err := client.readWithFormat(context.Background(), "email-1", "html")
	if err != nil {
		t.Fatal(err)
	}
	if htmlMessage.Body != "<div>Hello from Fastmail</div>" || htmlMessage.BodyType != "text/html" {
		t.Fatalf("unexpected HTML message: %+v", htmlMessage)
	}

	if _, _, _, err := client.downloadAttachment(context.Background(), "email-1", "blob-from-another-email"); err == nil {
		t.Fatal("expected an attachment from another email to be rejected")
	}

	path, size, contentType, err := client.downloadAttachment(context.Background(), "email-1", "blob-1")
	if err != nil {
		t.Fatal(err)
	}
	if filepath.Dir(path) != downloadDir || filepath.Base(path) != "report.pdf" {
		t.Fatalf("attachment escaped download directory: %q", path)
	}
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if string(contents) != "attachment data" || size != int64(len(contents)) || contentType != "application/pdf" {
		t.Fatalf("unexpected attachment result: %q %d %q", contents, size, contentType)
	}
}

func TestDownloadRejectsAttachmentFromAnotherEmail(t *testing.T) {
	client := &jmapClient{}
	// Validation happens before network access.
	_, _, _, err := client.downloadAttachment(context.Background(), "", "blob-1")
	if err == nil {
		t.Fatal("expected missing email ID to fail")
	}
}

func sampleEmail() map[string]any {
	return map[string]any{
		"id":            "email-1",
		"threadId":      "thread-1",
		"receivedAt":    "2026-07-17T12:00:00Z",
		"subject":       "Example",
		"from":          []any{map[string]any{"name": "Sender", "email": "sender@example.com"}},
		"to":            []any{map[string]any{"email": "me@example.com"}},
		"preview":       "Hello from Fastmail",
		"hasAttachment": true,
		"textBody":      []any{map[string]any{"partId": "body-1", "type": "text/plain"}},
		"htmlBody":      []any{map[string]any{"partId": "body-2", "type": "text/html"}},
		"bodyValues": map[string]any{
			"body-1": map[string]any{"value": "Hello from Fastmail", "isTruncated": false},
			"body-2": map[string]any{"value": "<div>Hello from Fastmail</div>", "isTruncated": false},
		},
		"attachments": []any{map[string]any{
			"partId": "part-2", "blobId": "blob-1", "type": "application/pdf", "name": "report.pdf", "size": 15,
		}},
	}
}

func writeTestJSON(t *testing.T, w http.ResponseWriter, value any) {
	t.Helper()
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(value); err != nil {
		t.Fatal(fmt.Errorf("write test response: %w", err))
	}
}
