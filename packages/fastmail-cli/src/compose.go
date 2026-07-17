package main

import (
	"context"
	"encoding/json"
	"fmt"
	"html"
	"strings"
	"unicode"
)

const (
	draftCreationID      = "draft"
	submissionCreationID = "send"
)

type identity struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
}

type messageBody struct {
	Plain string
	HTML  string
}

type mailbox struct {
	ID   string `json:"id"`
	Role string `json:"role"`
}

type identityGetResponse struct {
	List []identity `json:"list"`
}

type mailboxGetResponse struct {
	List []mailbox `json:"list"`
}

type setError struct {
	Type        string `json:"type"`
	Description string `json:"description"`
}

type createdObject struct {
	ID string `json:"id"`
}

type setResponse struct {
	Created    map[string]createdObject   `json:"created"`
	NotCreated map[string]setError        `json:"notCreated"`
	Updated    map[string]json.RawMessage `json:"updated"`
	NotUpdated map[string]setError        `json:"notUpdated"`
}

type draftResult struct {
	ID string
	To []address
}

type sendResult struct {
	EmailID      string
	SubmissionID string
	Recipient    string
	Warning      string
}

type selfDelivery struct {
	Identity identity
	DraftsID string
	SentID   string
}

func (c *jmapClient) createDraft(ctx context.Context, recipients []address, subject string, body messageBody) (draftResult, error) {
	if len(recipients) == 0 {
		return draftResult{}, fmt.Errorf("a draft requires at least one recipient")
	}
	delivery, err := c.selfDelivery(ctx, false)
	if err != nil {
		return draftResult{}, err
	}
	emailID, err := c.createDraftEmail(ctx, delivery, recipients, subject, body, nil, nil)
	if err != nil {
		return draftResult{}, err
	}
	return draftResult{ID: emailID, To: recipients}, nil
}

func (c *jmapClient) createReplyDraft(
	ctx context.Context,
	originalEmailID string,
	subjectOverride string,
	body messageBody,
) (draftResult, error) {
	delivery, err := c.selfDelivery(ctx, false)
	if err != nil {
		return draftResult{}, err
	}
	session, err := c.getSession(ctx)
	if err != nil {
		return draftResult{}, err
	}
	responses, err := c.call(
		ctx,
		methodCall{
			Name: "Email/get",
			ID:   "reply-source",
			Args: map[string]any{
				"accountId": session.PrimaryAccounts[mailCapability],
				"ids":       []string{originalEmailID},
				"properties": []string{
					"id", "from", "replyTo", "subject", "messageId", "references",
				},
			},
		},
	)
	if err != nil {
		return draftResult{}, fmt.Errorf("read reply source: %w", err)
	}
	var got emailGetResponse
	if err := json.Unmarshal(responses["reply-source"].Args, &got); err != nil {
		return draftResult{}, fmt.Errorf("decode reply source: %w", err)
	}
	if len(got.List) != 1 {
		return draftResult{}, fmt.Errorf("reply source email not found")
	}
	original := got.List[0]
	recipients := original.ReplyTo
	if len(recipients) == 0 {
		recipients = original.From
	}
	if len(recipients) == 0 {
		return draftResult{}, fmt.Errorf("reply source has no sender or reply-to address")
	}
	subject := subjectOverride
	if strings.TrimSpace(subject) == "" {
		subject = replySubject(original.Subject)
	}
	references := append([]string{}, original.References...)
	references = appendUnique(references, original.MessageID...)
	emailID, err := c.createDraftEmail(
		ctx,
		delivery,
		recipients,
		subject,
		body,
		original.MessageID,
		references,
	)
	if err != nil {
		return draftResult{}, err
	}
	return draftResult{ID: emailID, To: recipients}, nil
}

func (c *jmapClient) sendSelf(ctx context.Context, subject string, body messageBody) (sendResult, error) {
	delivery, err := c.selfDelivery(ctx, true)
	if err != nil {
		return sendResult{}, err
	}
	self := []address{{Name: delivery.Identity.Name, Email: delivery.Identity.Email}}
	emailID, err := c.createDraftEmail(ctx, delivery, self, subject, body, nil, nil)
	if err != nil {
		return sendResult{}, err
	}

	session, err := c.getSession(ctx)
	if err != nil {
		return sendResult{}, err
	}
	responses, err := c.callUsing(
		ctx,
		[]string{coreCapability, mailCapability, submissionCapability},
		methodCall{
			Name: "EmailSubmission/set",
			ID:   "submit",
			Args: map[string]any{
				"accountId": session.PrimaryAccounts[submissionCapability],
				"create": map[string]any{
					submissionCreationID: map[string]any{
						"identityId": delivery.Identity.ID,
						"emailId":    emailID,
						"envelope": map[string]any{
							"mailFrom": map[string]any{"email": delivery.Identity.Email},
							"rcptTo":   []map[string]any{{"email": delivery.Identity.Email}},
						},
					},
				},
				"onSuccessUpdateEmail": map[string]any{
					"#" + submissionCreationID: map[string]any{
						"mailboxIds/" + delivery.DraftsID: nil,
						"mailboxIds/" + delivery.SentID:   true,
						"keywords/$draft":                 nil,
					},
				},
			},
		},
	)
	if err != nil {
		return sendResult{}, fmt.Errorf("submit self-addressed email (draft %s was retained): %w", emailID, err)
	}
	submissionID, err := createdID(responses["submit"].Args, submissionCreationID)
	if err != nil {
		return sendResult{}, fmt.Errorf("submit self-addressed email (draft %s was retained): %w", emailID, err)
	}
	result := sendResult{
		EmailID:      emailID,
		SubmissionID: submissionID,
		Recipient:    delivery.Identity.Email,
	}
	if implicit, ok := responses["submit/implicit-error"]; ok {
		var cleanupError jmapError
		_ = json.Unmarshal(implicit.Args, &cleanupError)
		result.Warning = "message was sent, but Fastmail could not move the local copy from Drafts to Sent"
		if cleanupError.Description != "" {
			result.Warning += ": " + cleanupError.Description
		}
	} else if implicit, ok := responses["submit/implicit"]; ok {
		result.Warning = cleanupUpdateWarning(implicit, emailID)
	}
	return result, nil
}

func cleanupUpdateWarning(response methodResponse, emailID string) string {
	const warning = "message was sent, but Fastmail could not move the local copy from Drafts to Sent"
	if response.Name != "Email/set" {
		return warning + ": unexpected implicit response " + response.Name
	}
	var update setResponse
	if err := json.Unmarshal(response.Args, &update); err != nil {
		return warning + ": could not decode Fastmail's cleanup response"
	}
	if rejected, ok := update.NotUpdated[emailID]; ok {
		description := rejected.Description
		if description == "" {
			description = rejected.Type
		}
		if description != "" {
			return warning + ": " + description
		}
		return warning
	}
	if _, updated := update.Updated[emailID]; !updated {
		return warning + ": Fastmail did not confirm the cleanup update"
	}
	return ""
}

func (c *jmapClient) selfDelivery(ctx context.Context, requireSentMailbox bool) (selfDelivery, error) {
	session, err := c.getSession(ctx)
	if err != nil {
		return selfDelivery{}, err
	}
	if session.Username == "" {
		return selfDelivery{}, fmt.Errorf("Fastmail session did not identify the account username")
	}
	submissionAccountID := session.PrimaryAccounts[submissionCapability]
	if submissionAccountID == "" {
		return selfDelivery{}, fmt.Errorf("Fastmail API token does not provide the submission capability")
	}

	responses, err := c.callUsing(
		ctx,
		[]string{coreCapability, submissionCapability},
		methodCall{
			Name: "Identity/get",
			ID:   "identities",
			Args: map[string]any{
				"accountId":  submissionAccountID,
				"properties": []string{"id", "name", "email"},
			},
		},
	)
	if err != nil {
		return selfDelivery{}, err
	}
	var identities identityGetResponse
	if err := json.Unmarshal(responses["identities"].Args, &identities); err != nil {
		return selfDelivery{}, fmt.Errorf("decode Identity/get: %w", err)
	}
	var selected identity
	for _, candidate := range identities.List {
		if strings.EqualFold(candidate.Email, session.Username) {
			selected = candidate
			break
		}
	}
	if selected.ID == "" {
		return selfDelivery{}, fmt.Errorf("no sending identity exactly matches the Fastmail account username")
	}

	responses, err = c.call(
		ctx,
		methodCall{
			Name: "Mailbox/get",
			ID:   "mailboxes",
			Args: map[string]any{
				"accountId":  session.PrimaryAccounts[mailCapability],
				"properties": []string{"id", "role"},
			},
		},
	)
	if err != nil {
		return selfDelivery{}, err
	}
	var mailboxes mailboxGetResponse
	if err := json.Unmarshal(responses["mailboxes"].Args, &mailboxes); err != nil {
		return selfDelivery{}, fmt.Errorf("decode Mailbox/get: %w", err)
	}
	delivery := selfDelivery{Identity: selected}
	for _, candidate := range mailboxes.List {
		switch candidate.Role {
		case "drafts":
			delivery.DraftsID = candidate.ID
		case "sent":
			delivery.SentID = candidate.ID
		}
	}
	if delivery.DraftsID == "" {
		return selfDelivery{}, fmt.Errorf("Fastmail account has no drafts mailbox")
	}
	if requireSentMailbox && delivery.SentID == "" {
		return selfDelivery{}, fmt.Errorf("Fastmail account has no sent mailbox")
	}
	return delivery, nil
}

func (c *jmapClient) createDraftEmail(
	ctx context.Context,
	delivery selfDelivery,
	recipients []address,
	subject string,
	body messageBody,
	inReplyTo []string,
	references []string,
) (string, error) {
	session, err := c.getSession(ctx)
	if err != nil {
		return "", err
	}
	from := address{Name: delivery.Identity.Name, Email: delivery.Identity.Email}
	email := map[string]any{
		"mailboxIds": map[string]bool{delivery.DraftsID: true},
		"keywords":   map[string]bool{"$draft": true, "$seen": true},
		"from":       []address{from},
		"to":         recipients,
		"subject":    subject,
	}
	if body.HTML == "" {
		email["bodyStructure"] = map[string]any{
			"partId": "text",
			"type":   "text/plain",
		}
		email["bodyValues"] = map[string]any{
			"text": map[string]string{"value": body.Plain},
		}
	} else {
		email["bodyStructure"] = map[string]any{
			"type": "multipart/alternative",
			"subParts": []map[string]any{
				{"partId": "text", "type": "text/plain"},
				{"partId": "html", "type": "text/html"},
			},
		}
		email["bodyValues"] = map[string]any{
			"text": map[string]string{"value": body.Plain},
			"html": map[string]string{"value": body.HTML},
		}
	}
	if len(inReplyTo) > 0 {
		email["inReplyTo"] = inReplyTo
	}
	if len(references) > 0 {
		email["references"] = references
	}
	responses, err := c.call(
		ctx,
		methodCall{
			Name: "Email/set",
			ID:   "create-draft",
			Args: map[string]any{
				"accountId": session.PrimaryAccounts[mailCapability],
				"create": map[string]any{
					draftCreationID: email,
				},
			},
		},
	)
	if err != nil {
		return "", fmt.Errorf("create draft: %w", err)
	}
	emailID, err := createdID(responses["create-draft"].Args, draftCreationID)
	if err != nil {
		return "", fmt.Errorf("create draft: %w", err)
	}
	return emailID, nil
}

func newHTMLMessageBody(value string) messageBody {
	return messageBody{
		Plain: htmlToPlainText(value),
		HTML:  wrapHTMLDocument(value),
	}
}

func wrapHTMLDocument(value string) string {
	lower := strings.ToLower(value)
	if strings.Contains(lower, "<html") {
		return value
	}
	return "<!DOCTYPE html><html><head><title></title></head><body>" + value + "</body></html>"
}

func htmlToPlainText(value string) string {
	var output strings.Builder
	skipTag := ""
	for position := 0; position < len(value); {
		if value[position] != '<' {
			end := strings.IndexByte(value[position:], '<')
			if end < 0 {
				end = len(value) - position
			}
			if skipTag == "" {
				output.WriteString(html.UnescapeString(value[position : position+end]))
			}
			position += end
			continue
		}
		if strings.HasPrefix(value[position:], "<!--") {
			end := strings.Index(value[position+4:], "-->")
			if end < 0 {
				break
			}
			position += end + 7
			continue
		}
		end := htmlTagEnd(value, position+1)
		if end < 0 {
			if skipTag == "" {
				output.WriteString(html.UnescapeString(value[position:]))
			}
			break
		}
		tag, closing := htmlTagName(value[position+1 : end])
		if skipTag != "" {
			if closing && tag == skipTag {
				skipTag = ""
			}
			position = end + 1
			continue
		}
		if !closing && (tag == "head" || tag == "script" || tag == "style") {
			skipTag = tag
			position = end + 1
			continue
		}
		switch tag {
		case "br":
			output.WriteByte('\n')
		case "li":
			if !closing {
				writeTextBoundary(&output)
				output.WriteString("- ")
			} else {
				writeTextBoundary(&output)
			}
		case "div", "p", "blockquote", "tr", "h1", "h2", "h3", "h4", "h5", "h6":
			if closing {
				output.WriteByte('\n')
			}
		}
		position = end + 1
	}
	return cleanPlainText(output.String())
}

func htmlTagEnd(value string, start int) int {
	var quote byte
	for index := start; index < len(value); index++ {
		char := value[index]
		if quote != 0 {
			if char == quote {
				quote = 0
			}
			continue
		}
		if char == '\'' || char == '"' {
			quote = char
			continue
		}
		if char == '>' {
			return index
		}
	}
	return -1
}

func htmlTagName(raw string) (string, bool) {
	raw = strings.TrimSpace(raw)
	closing := strings.HasPrefix(raw, "/")
	if closing {
		raw = strings.TrimSpace(strings.TrimPrefix(raw, "/"))
	}
	end := 0
	for end < len(raw) {
		r := rune(raw[end])
		if !unicode.IsLetter(r) && !unicode.IsDigit(r) {
			break
		}
		end++
	}
	return strings.ToLower(raw[:end]), closing
}

func writeTextBoundary(output *strings.Builder) {
	if output.Len() == 0 {
		return
	}
	value := output.String()
	if value[len(value)-1] != '\n' {
		output.WriteByte('\n')
	}
}

func cleanPlainText(value string) string {
	value = strings.ReplaceAll(value, "\r\n", "\n")
	value = strings.ReplaceAll(value, "\r", "\n")
	value = strings.ReplaceAll(value, "\u00a0", " ")
	lines := strings.Split(value, "\n")
	cleaned := make([]string, 0, len(lines))
	blank := false
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			if len(cleaned) == 0 || blank {
				continue
			}
			blank = true
			cleaned = append(cleaned, "")
			continue
		}
		blank = false
		cleaned = append(cleaned, line)
	}
	for len(cleaned) > 0 && cleaned[len(cleaned)-1] == "" {
		cleaned = cleaned[:len(cleaned)-1]
	}
	return strings.Join(cleaned, "\n")
}

func replySubject(subject string) string {
	trimmed := strings.TrimSpace(subject)
	if strings.HasPrefix(strings.ToLower(trimmed), "re:") {
		return trimmed
	}
	if trimmed == "" {
		return "Re:"
	}
	return "Re: " + trimmed
}

func appendUnique(values []string, additions ...string) []string {
	seen := make(map[string]struct{}, len(values)+len(additions))
	result := make([]string, 0, len(values)+len(additions))
	for _, value := range append(values, additions...) {
		if value == "" {
			continue
		}
		if _, ok := seen[value]; ok {
			continue
		}
		seen[value] = struct{}{}
		result = append(result, value)
	}
	return result
}

func createdID(raw json.RawMessage, creationID string) (string, error) {
	var response setResponse
	if err := json.Unmarshal(raw, &response); err != nil {
		return "", fmt.Errorf("decode set response: %w", err)
	}
	if created := response.Created[creationID]; created.ID != "" {
		return created.ID, nil
	}
	if rejected, ok := response.NotCreated[creationID]; ok {
		description := rejected.Description
		if description == "" {
			description = rejected.Type
		}
		return "", fmt.Errorf("Fastmail rejected creation: %s", description)
	}
	return "", fmt.Errorf("Fastmail response did not contain a created object")
}
