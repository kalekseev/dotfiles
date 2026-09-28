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
	draftCreationID       = "draft"
	replacementCreationID = "replacement"
	submissionCreationID  = "send"
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

type identityGetResponse struct {
	List []identity `json:"list"`
}

type setError struct {
	Type        string `json:"type"`
	Description string `json:"description"`
}

type createdObject struct {
	ID string `json:"id"`
}

type setResponse struct {
	NewState     string                     `json:"newState"`
	Created      map[string]createdObject   `json:"created"`
	NotCreated   map[string]setError        `json:"notCreated"`
	Updated      map[string]json.RawMessage `json:"updated"`
	NotUpdated   map[string]setError        `json:"notUpdated"`
	Destroyed    []string                   `json:"destroyed"`
	NotDestroyed map[string]setError        `json:"notDestroyed"`
}

type draftResult struct {
	ID string
	To []address
}

type draftChanges struct {
	Subject    *string
	Body       *messageBody
	Recipients []address
}

type draftTarget struct {
	State         string
	HasAttachment bool
	Email         map[string]any
}

type draftEditResult struct {
	ID         string
	ReplacedID string
	Updated    []string
	Warning    string
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

func (c *jmapClient) editDraft(ctx context.Context, draftID string, changes draftChanges) (draftEditResult, error) {
	target, err := c.draftTarget(ctx, draftID, true)
	if err != nil {
		return draftEditResult{}, err
	}
	if changes.Body != nil && target.HasAttachment {
		return draftEditResult{}, fmt.Errorf("draft %s has attachments. Body replacement removes them", draftID)
	}

	replacement := target.Email
	sanitizeDraftBody(replacement)
	updated := make([]string, 0, 3)
	if len(changes.Recipients) > 0 {
		replacement["to"] = changes.Recipients
		updated = append(updated, "to")
	}
	if changes.Subject != nil {
		replacement["subject"] = *changes.Subject
		updated = append(updated, "subject")
	}
	if changes.Body != nil {
		setMessageBody(replacement, *changes.Body)
		updated = append(updated, "body")
	}

	session, err := c.getSession(ctx)
	if err != nil {
		return draftEditResult{}, err
	}
	responses, err := c.call(ctx, methodCall{
		Name: "Email/set",
		ID:   "edit-draft",
		Args: map[string]any{
			"accountId": session.PrimaryAccounts[mailCapability],
			"ifInState": target.State,
			"create":    map[string]any{replacementCreationID: replacement},
		},
	})
	if err != nil {
		return draftEditResult{}, fmt.Errorf("edit draft: %w", err)
	}
	replacementID, err := createdID(responses["edit-draft"].Args, replacementCreationID)
	if err != nil {
		return draftEditResult{}, fmt.Errorf("edit draft: %w", err)
	}
	result := draftEditResult{ID: replacementID, ReplacedID: draftID, Updated: updated}
	newState, err := newSetState(responses["edit-draft"].Args)
	if err != nil {
		result.Warning = fmt.Sprintf("replacement draft %s was created, but original draft %s was retained: %v", replacementID, draftID, err)
		return result, nil
	}
	if err := c.destroyDraftAtState(ctx, draftID, newState); err != nil {
		result.Warning = fmt.Sprintf("replacement draft %s was created, but original draft %s was retained: %v", replacementID, draftID, err)
	}
	return result, nil
}

func (c *jmapClient) deleteDraft(ctx context.Context, draftID string) error {
	target, err := c.draftTarget(ctx, draftID, false)
	if err != nil {
		return err
	}
	return c.destroyDraftAtState(ctx, draftID, target.State)
}

func (c *jmapClient) destroyDraftAtState(ctx context.Context, draftID, state string) error {
	session, err := c.getSession(ctx)
	if err != nil {
		return err
	}
	responses, err := c.call(ctx, methodCall{
		Name: "Email/set",
		ID:   "delete-draft",
		Args: map[string]any{
			"accountId": session.PrimaryAccounts[mailCapability],
			"ifInState": state,
			"destroy":   []string{draftID},
		},
	})
	if err != nil {
		return fmt.Errorf("delete draft: %w", err)
	}
	if err := destroyedObject(responses["delete-draft"].Args, draftID); err != nil {
		return fmt.Errorf("delete draft: %w", err)
	}
	return nil
}

func (c *jmapClient) draftTarget(ctx context.Context, draftID string, includeContent bool) (draftTarget, error) {
	mailboxes, err := c.getMailboxes(ctx)
	if err != nil {
		return draftTarget{}, err
	}
	draftsID := ""
	for _, mailbox := range mailboxes {
		if mailbox.Role == "drafts" {
			draftsID = mailbox.ID
			break
		}
	}
	if draftsID == "" {
		return draftTarget{}, fmt.Errorf("Fastmail account has no drafts mailbox")
	}
	session, err := c.getSession(ctx)
	if err != nil {
		return draftTarget{}, err
	}
	properties := []string{"id", "mailboxIds", "keywords", "hasAttachment"}
	if includeContent {
		properties = append(properties,
			"from", "to", "cc", "bcc", "replyTo", "subject", "sentAt", "receivedAt",
			"inReplyTo", "references", "bodyStructure", "bodyValues",
		)
	}
	arguments := map[string]any{
		"accountId":  session.PrimaryAccounts[mailCapability],
		"ids":        []string{draftID},
		"properties": properties,
	}
	if includeContent {
		arguments["fetchAllBodyValues"] = true
		arguments["maxBodyValueBytes"] = 0
	}
	responses, err := c.call(ctx, methodCall{
		Name: "Email/get",
		ID:   "draft-target",
		Args: arguments,
	})
	if err != nil {
		return draftTarget{}, fmt.Errorf("read draft: %w", err)
	}
	var got struct {
		State string            `json:"state"`
		List  []json.RawMessage `json:"list"`
	}
	if err := json.Unmarshal(responses["draft-target"].Args, &got); err != nil {
		return draftTarget{}, fmt.Errorf("decode draft: %w", err)
	}
	if len(got.List) != 1 {
		return draftTarget{}, fmt.Errorf("draft %s not found", draftID)
	}
	var draft jmapEmail
	if err := json.Unmarshal(got.List[0], &draft); err != nil {
		return draftTarget{}, fmt.Errorf("decode draft properties: %w", err)
	}
	if !draft.Keywords["$draft"] || !draft.MailboxIDs[draftsID] {
		return draftTarget{}, fmt.Errorf("email %s is not a draft", draftID)
	}
	if got.State == "" {
		return draftTarget{}, fmt.Errorf("Fastmail did not return the draft state")
	}
	target := draftTarget{State: got.State, HasAttachment: draft.HasAttachment}
	if includeContent {
		if err := json.Unmarshal(got.List[0], &target.Email); err != nil {
			return draftTarget{}, fmt.Errorf("decode draft content: %w", err)
		}
		delete(target.Email, "id")
		delete(target.Email, "hasAttachment")
	}
	return target, nil
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

	mailboxes, err := c.getMailboxes(ctx)
	if err != nil {
		return selfDelivery{}, err
	}
	delivery := selfDelivery{Identity: selected}
	for _, candidate := range mailboxes {
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
	setMessageBody(email, body)
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

func setMessageBody(email map[string]any, body messageBody) {
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
}

func sanitizeDraftBody(email map[string]any) {
	bodyValues, _ := email["bodyValues"].(map[string]any)
	structure, _ := email["bodyStructure"].(map[string]any)
	sanitizeDraftBodyPart(structure, bodyValues)
}

func sanitizeDraftBodyPart(part map[string]any, bodyValues map[string]any) {
	if part == nil {
		return
	}
	partID, _ := part["partId"].(string)
	_, hasBodyValue := bodyValues[partID]
	if partID != "" && hasBodyValue {
		delete(part, "blobId")
		delete(part, "size")
		delete(part, "charset")
	} else if _, hasBlob := part["blobId"]; hasBlob {
		delete(part, "partId")
		delete(part, "size")
	}
	subParts, _ := part["subParts"].([]any)
	for _, raw := range subParts {
		child, _ := raw.(map[string]any)
		sanitizeDraftBodyPart(child, bodyValues)
	}
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

func newSetState(raw json.RawMessage) (string, error) {
	var response setResponse
	if err := json.Unmarshal(raw, &response); err != nil {
		return "", fmt.Errorf("decode set response: %w", err)
	}
	if response.NewState == "" {
		return "", fmt.Errorf("Fastmail response did not contain the new email state")
	}
	return response.NewState, nil
}

func destroyedObject(raw json.RawMessage, objectID string) error {
	var response setResponse
	if err := json.Unmarshal(raw, &response); err != nil {
		return fmt.Errorf("decode set response: %w", err)
	}
	for _, destroyed := range response.Destroyed {
		if destroyed == objectID {
			return nil
		}
	}
	if rejected, ok := response.NotDestroyed[objectID]; ok {
		return fmt.Errorf("Fastmail rejected deletion: %s", setErrorDescription(rejected))
	}
	return fmt.Errorf("Fastmail response did not confirm the deletion")
}

func setErrorDescription(rejected setError) string {
	if rejected.Description != "" {
		return rejected.Description
	}
	if rejected.Type != "" {
		return rejected.Type
	}
	return "unknown error"
}
