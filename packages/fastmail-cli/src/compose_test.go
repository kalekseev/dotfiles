package main

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

type capturedDraft struct {
	From          []address `json:"from"`
	To            []address `json:"to"`
	Subject       string    `json:"subject"`
	InReplyTo     []string  `json:"inReplyTo"`
	References    []string  `json:"references"`
	BodyStructure struct {
		PartID   string `json:"partId"`
		Type     string `json:"type"`
		SubParts []struct {
			PartID string `json:"partId"`
			Type   string `json:"type"`
		} `json:"subParts"`
	} `json:"bodyStructure"`
	BodyValues map[string]struct {
		Value string `json:"value"`
	} `json:"bodyValues"`
}

type capturedSubmission struct {
	IdentityID string `json:"identityId"`
	EmailID    string `json:"emailId"`
	Envelope   struct {
		MailFrom address   `json:"mailFrom"`
		RcptTo   []address `json:"rcptTo"`
	} `json:"envelope"`
}

func TestDraftReplyAndSendRecipientBoundaries(t *testing.T) {
	const (
		selfAddress  = "me@example.com"
		token        = "test-token"
		draftID      = "draft-id"
		submissionID = "submission-id"
	)
	var drafts []capturedDraft
	var submission capturedSubmission
	submissionCalls := 0
	var server *httptest.Server
	server = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer "+token {
			http.Error(w, "unauthorized", http.StatusUnauthorized)
			return
		}
		if r.URL.Path == "/session" {
			writeTestJSON(t, w, map[string]any{
				"apiUrl":      server.URL + "/api",
				"downloadUrl": server.URL + "/download/{accountId}/{blobId}/{name}?type={type}",
				"username":    selfAddress,
				"primaryAccounts": map[string]string{
					mailCapability:       "mail-account",
					submissionCapability: "submission-account",
				},
			})
			return
		}
		if r.URL.Path != "/api" {
			http.NotFound(w, r)
			return
		}

		var request struct {
			Using       []string          `json:"using"`
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
		var methodName, callID string
		_ = json.Unmarshal(tuple[0], &methodName)
		_ = json.Unmarshal(tuple[2], &callID)

		switch methodName {
		case "Identity/get":
			writeTestJSON(t, w, map[string]any{"methodResponses": []any{
				[]any{"Identity/get", map[string]any{"list": []any{map[string]any{
					"id": "identity-id", "name": "Me", "email": selfAddress,
				}}}, callID},
			}})
		case "Mailbox/get":
			writeTestJSON(t, w, map[string]any{"methodResponses": []any{
				[]any{"Mailbox/get", map[string]any{"list": []any{
					map[string]any{"id": "drafts-id", "role": "drafts"},
					map[string]any{"id": "sent-id", "role": "sent"},
				}}, callID},
			}})
		case "Email/get":
			writeTestJSON(t, w, map[string]any{"methodResponses": []any{
				[]any{"Email/get", map[string]any{"list": []any{map[string]any{
					"id":         "original-id",
					"from":       []any{map[string]any{"email": "sender@example.net"}},
					"replyTo":    []any{map[string]any{"name": "Replies", "email": "reply@example.net"}},
					"subject":    "Original subject",
					"messageId":  []string{"original@example.net"},
					"references": []string{"older@example.net"},
				}}}, callID},
			}})
		case "Email/set":
			var arguments struct {
				Create map[string]capturedDraft `json:"create"`
			}
			if err := json.Unmarshal(tuple[1], &arguments); err != nil {
				t.Error(err)
				return
			}
			drafts = append(drafts, arguments.Create[draftCreationID])
			writeTestJSON(t, w, map[string]any{"methodResponses": []any{
				[]any{"Email/set", map[string]any{"created": map[string]any{
					draftCreationID: map[string]any{"id": draftID},
				}}, callID},
			}})
		case "EmailSubmission/set":
			submissionCalls++
			var arguments struct {
				Create map[string]capturedSubmission `json:"create"`
			}
			if err := json.Unmarshal(tuple[1], &arguments); err != nil {
				t.Error(err)
				return
			}
			submission = arguments.Create[submissionCreationID]
			cleanupResult := map[string]any{"updated": map[string]any{draftID: nil}}
			if submissionCalls > 1 {
				cleanupResult = map[string]any{"notUpdated": map[string]any{
					draftID: map[string]any{"type": "serverFail", "description": "mailbox update failed"},
				}}
			}
			writeTestJSON(t, w, map[string]any{"methodResponses": []any{
				[]any{"EmailSubmission/set", map[string]any{"created": map[string]any{
					submissionCreationID: map[string]any{"id": submissionID},
				}}, callID},
				// JMAP returns this second implicit response for onSuccessUpdateEmail.
				[]any{"Email/set", cleanupResult, callID},
			}})
		default:
			t.Errorf("unexpected method %q", methodName)
			http.Error(w, "unexpected method", http.StatusBadRequest)
		}
	}))
	defer server.Close()

	client := newJMAPClient(token, t.TempDir())
	client.sessionURL = server.URL + "/session"
	client.allowTestServer = true
	client.httpClient = server.Client()

	arbitrary := []address{{Name: "Alice", Email: "alice@example.org"}}
	created, err := client.createDraft(context.Background(), arbitrary, "Draft subject", messageBody{Plain: "Draft body"})
	if err != nil {
		t.Fatal(err)
	}
	if created.ID != draftID || len(created.To) != 1 || created.To[0].Email != "alice@example.org" {
		t.Fatalf("unexpected arbitrary draft result: %+v", created)
	}

	richBody := newHTMLMessageBody("<div>Hello <strong>Alice &amp; Bob</strong>.</div><div><br></div><ul><li>First</li><li>Second</li></ul><script>ignored()</script>")
	if _, err := client.createDraft(context.Background(), arbitrary, "Rich draft", richBody); err != nil {
		t.Fatal(err)
	}

	reply, err := client.createReplyDraft(context.Background(), "original-id", "", messageBody{Plain: "Reply body"})
	if err != nil {
		t.Fatal(err)
	}
	if len(reply.To) != 1 || reply.To[0].Email != "reply@example.net" {
		t.Fatalf("reply did not prefer Reply-To: %+v", reply)
	}

	sent, err := client.sendSelf(context.Background(), "Note to self", messageBody{Plain: "Self body"})
	if err != nil {
		t.Fatal(err)
	}
	if sent.EmailID != draftID || sent.SubmissionID != submissionID || sent.Recipient != selfAddress {
		t.Fatalf("unexpected send result: %+v", sent)
	}
	if sent.Warning != "" {
		t.Fatalf("successful cleanup returned warning %q", sent.Warning)
	}

	if len(drafts) != 4 {
		t.Fatalf("captured %d drafts, want 4", len(drafts))
	}
	if drafts[0].To[0].Email != "alice@example.org" {
		t.Fatalf("arbitrary draft recipient changed: %+v", drafts[0].To)
	}
	if drafts[0].BodyStructure.Type != "text/plain" || drafts[0].BodyValues["text"].Value != "Draft body" {
		t.Fatalf("plain draft body is wrong: %+v", drafts[0])
	}
	if drafts[1].BodyStructure.Type != "multipart/alternative" || len(drafts[1].BodyStructure.SubParts) != 2 {
		t.Fatalf("rich draft is not multipart/alternative: %+v", drafts[1].BodyStructure)
	}
	if got := drafts[1].BodyValues["text"].Value; got != "Hello Alice & Bob.\n\n- First\n- Second" {
		t.Fatalf("unexpected generated text fallback: %q", got)
	}
	if got := drafts[1].BodyValues["html"].Value; got != richBody.HTML {
		t.Fatalf("unexpected HTML body: %q", got)
	}
	if drafts[2].To[0].Email != "reply@example.net" || drafts[2].Subject != "Re: Original subject" {
		t.Fatalf("reply draft metadata is wrong: %+v", drafts[2])
	}
	if len(drafts[2].InReplyTo) != 1 || drafts[2].InReplyTo[0] != "original@example.net" {
		t.Fatalf("reply draft has wrong In-Reply-To: %+v", drafts[2].InReplyTo)
	}
	if len(drafts[2].References) != 2 || drafts[2].References[1] != "original@example.net" {
		t.Fatalf("reply draft has wrong References: %+v", drafts[2].References)
	}
	if len(drafts[3].To) != 1 || drafts[3].To[0].Email != selfAddress {
		t.Fatalf("send message was not addressed only to self: %+v", drafts[3].To)
	}
	if submission.IdentityID != "identity-id" || submission.EmailID != draftID {
		t.Fatalf("unexpected submission: %+v", submission)
	}
	if submission.Envelope.MailFrom.Email != selfAddress || len(submission.Envelope.RcptTo) != 1 || submission.Envelope.RcptTo[0].Email != selfAddress {
		t.Fatalf("submission envelope was not restricted to self: %+v", submission.Envelope)
	}

	sentWithCleanupFailure, err := client.sendSelf(context.Background(), "Second note", messageBody{Plain: "Self body"})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(sentWithCleanupFailure.Warning, "mailbox update failed") {
		t.Fatalf("implicit Email/set failure was hidden: %+v", sentWithCleanupFailure)
	}
}

func TestReplySubjectAndReferences(t *testing.T) {
	if got := replySubject("Re: Existing"); got != "Re: Existing" {
		t.Fatalf("replySubject duplicated prefix: %q", got)
	}
	got := appendUnique([]string{"one", "two"}, "two", "three", "")
	if len(got) != 3 || got[2] != "three" {
		t.Fatalf("appendUnique returned %+v", got)
	}
}
