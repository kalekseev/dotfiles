package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode"
	"unicode/utf8"
)

const (
	defaultSessionURL       = "https://api.fastmail.com/jmap/session"
	coreCapability          = "urn:ietf:params:jmap:core"
	mailCapability          = "urn:ietf:params:jmap:mail"
	submissionCapability    = "urn:ietf:params:jmap:submission"
	defaultMaxBodyBytes     = 512 * 1024
	defaultMaxDownloadBytes = 25 * 1024 * 1024
)

type address struct {
	Name  string `json:"name,omitempty"`
	Email string `json:"email"`
}

type attachment struct {
	ID   string `json:"id" jsonschema:"Opaque attachment ID to pass to download_attachment"`
	Name string `json:"name"`
	Type string `json:"type"`
	Size int64  `json:"size"`
}

type emailSummary struct {
	ID            string       `json:"id"`
	ThreadID      string       `json:"thread_id"`
	ReceivedAt    string       `json:"received_at"`
	Subject       string       `json:"subject"`
	From          []address    `json:"from"`
	To            []address    `json:"to"`
	Preview       string       `json:"preview"`
	HasAttachment bool         `json:"has_attachment"`
	Attachments   []attachment `json:"attachments,omitempty"`
}

type emailMessage struct {
	ID            string       `json:"id"`
	ThreadID      string       `json:"thread_id"`
	ReceivedAt    string       `json:"received_at"`
	Subject       string       `json:"subject"`
	From          []address    `json:"from"`
	To            []address    `json:"to"`
	CC            []address    `json:"cc,omitempty"`
	BCC           []address    `json:"bcc,omitempty"`
	ReplyTo       []address    `json:"reply_to,omitempty"`
	BodyType      string       `json:"body_type"`
	Body          string       `json:"body"`
	BodyTruncated bool         `json:"body_truncated"`
	Attachments   []attachment `json:"attachments,omitempty"`
}

type searchFilter struct {
	Text          string `json:"text,omitempty"`
	From          string `json:"from,omitempty"`
	To            string `json:"to,omitempty"`
	Subject       string `json:"subject,omitempty"`
	After         string `json:"after,omitempty"`
	Before        string `json:"before,omitempty"`
	HasAttachment *bool  `json:"hasAttachment,omitempty"`
	NotKeyword    string `json:"notKeyword,omitempty"`
}

type searchOptions struct {
	Filter searchFilter
	Limit  int
}

type jmapClient struct {
	token              string
	httpClient         *http.Client
	sessionURL         string
	allowTestServer    bool
	maxBodyBytes       int
	maxAttachmentBytes int64
	downloadDir        string

	mu      sync.Mutex
	session *jmapSession
}

type jmapSession struct {
	APIURL          string            `json:"apiUrl"`
	DownloadURL     string            `json:"downloadUrl"`
	PrimaryAccounts map[string]string `json:"primaryAccounts"`
	Username        string            `json:"username"`
}

type methodCall struct {
	Name string
	Args any
	ID   string
}

type methodResponse struct {
	Name string
	Args json.RawMessage
	ID   string
}

type jmapEnvelope struct {
	MethodResponses []json.RawMessage `json:"methodResponses"`
}

type jmapError struct {
	Type        string `json:"type"`
	Description string `json:"description"`
}

type emailQueryResponse struct {
	IDs      []string `json:"ids"`
	Position int      `json:"position"`
	Total    int      `json:"total"`
}

type emailGetResponse struct {
	List     []jmapEmail `json:"list"`
	NotFound []string    `json:"notFound"`
}

type jmapEmail struct {
	ID            string               `json:"id"`
	ThreadID      string               `json:"threadId"`
	ReceivedAt    string               `json:"receivedAt"`
	Subject       string               `json:"subject"`
	From          []address            `json:"from"`
	To            []address            `json:"to"`
	CC            []address            `json:"cc"`
	BCC           []address            `json:"bcc"`
	ReplyTo       []address            `json:"replyTo"`
	MessageID     []string             `json:"messageId"`
	References    []string             `json:"references"`
	Preview       string               `json:"preview"`
	HasAttachment bool                 `json:"hasAttachment"`
	TextBody      []jmapPart           `json:"textBody"`
	HTMLBody      []jmapPart           `json:"htmlBody"`
	Attachments   []jmapPart           `json:"attachments"`
	BodyValues    map[string]bodyValue `json:"bodyValues"`
}

type jmapPart struct {
	PartID      string `json:"partId"`
	BlobID      string `json:"blobId"`
	Type        string `json:"type"`
	Name        string `json:"name"`
	Size        int64  `json:"size"`
	Disposition string `json:"disposition"`
}

type bodyValue struct {
	Value       string `json:"value"`
	IsTruncated bool   `json:"isTruncated"`
}

func newJMAPClient(token, downloadDir string) *jmapClient {
	client := &jmapClient{
		token:              token,
		sessionURL:         defaultSessionURL,
		maxBodyBytes:       defaultMaxBodyBytes,
		maxAttachmentBytes: defaultMaxDownloadBytes,
		downloadDir:        downloadDir,
	}
	client.httpClient = &http.Client{
		Timeout: 30 * time.Second,
		// The bearer token must never follow a redirect to another origin.
		CheckRedirect: func(_ *http.Request, _ []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}
	return client
}

func defaultDownloadDir() (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("find home directory: %w", err)
	}
	return filepath.Join(home, "Downloads", "Fastmail"), nil
}

func configuredDownloadDir() (string, error) {
	dir := os.Getenv("FASTMAIL_DOWNLOAD_DIR")
	if dir == "" {
		return defaultDownloadDir()
	}
	abs, err := filepath.Abs(dir)
	if err != nil {
		return "", fmt.Errorf("resolve FASTMAIL_DOWNLOAD_DIR: %w", err)
	}
	return abs, nil
}

func configuredMaxAttachmentBytes() (int64, error) {
	raw := os.Getenv("FASTMAIL_MAX_ATTACHMENT_BYTES")
	if raw == "" {
		return defaultMaxDownloadBytes, nil
	}
	value, err := strconv.ParseInt(raw, 10, 64)
	if err != nil || value <= 0 {
		return 0, fmt.Errorf("FASTMAIL_MAX_ATTACHMENT_BYTES must be a positive integer")
	}
	return value, nil
}

func (c *jmapClient) getSession(ctx context.Context) (*jmapSession, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.session != nil {
		return c.session, nil
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.sessionURL, nil)
	if err != nil {
		return nil, fmt.Errorf("create JMAP session request: %w", err)
	}
	c.authorize(req)
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("fetch JMAP session: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, httpStatusError("fetch JMAP session", resp)
	}

	var session jmapSession
	if err := decodeLimitedJSON(resp.Body, &session); err != nil {
		return nil, fmt.Errorf("decode JMAP session: %w", err)
	}
	if session.APIURL == "" || session.DownloadURL == "" || session.PrimaryAccounts[mailCapability] == "" {
		return nil, fmt.Errorf("Fastmail JMAP session is missing required mail endpoints")
	}
	if err := c.validateFastmailURL(session.APIURL); err != nil {
		return nil, fmt.Errorf("reject JMAP API URL: %w", err)
	}
	if err := c.validateFastmailURL(session.DownloadURL); err != nil {
		return nil, fmt.Errorf("reject JMAP download URL: %w", err)
	}
	c.session = &session
	return c.session, nil
}

func (c *jmapClient) authorize(req *http.Request) {
	req.Header.Set("Authorization", "Bearer "+c.token)
}

func (c *jmapClient) validateFastmailURL(raw string) error {
	parsed, err := url.Parse(raw)
	if err != nil {
		return err
	}
	if c.allowTestServer {
		return nil
	}
	if parsed.Scheme != "https" || parsed.User != nil {
		return fmt.Errorf("URL must use HTTPS without user information")
	}
	host := strings.ToLower(parsed.Hostname())
	if !hostMatches(host, "fastmail.com") && !hostMatches(host, "fastmailusercontent.com") {
		return fmt.Errorf("host %q is outside the Fastmail allowlist", host)
	}
	return nil
}

func hostMatches(host, suffix string) bool {
	return host == suffix || strings.HasSuffix(host, "."+suffix)
}

func (c *jmapClient) call(ctx context.Context, calls ...methodCall) (map[string]methodResponse, error) {
	return c.callUsing(ctx, []string{coreCapability, mailCapability}, calls...)
}

func (c *jmapClient) callUsing(ctx context.Context, capabilities []string, calls ...methodCall) (map[string]methodResponse, error) {
	session, err := c.getSession(ctx)
	if err != nil {
		return nil, err
	}

	wireCalls := make([]any, 0, len(calls))
	for _, call := range calls {
		wireCalls = append(wireCalls, []any{call.Name, call.Args, call.ID})
	}
	payload := struct {
		Using       []string `json:"using"`
		MethodCalls []any    `json:"methodCalls"`
	}{
		Using:       capabilities,
		MethodCalls: wireCalls,
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("encode JMAP request: %w", err)
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, session.APIURL, strings.NewReader(string(body)))
	if err != nil {
		return nil, fmt.Errorf("create JMAP request: %w", err)
	}
	c.authorize(req)
	req.Header.Set("Content-Type", "application/json")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("call JMAP: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, httpStatusError("call JMAP", resp)
	}

	var envelope jmapEnvelope
	if err := decodeLimitedJSON(resp.Body, &envelope); err != nil {
		return nil, fmt.Errorf("decode JMAP response: %w", err)
	}
	responses := make(map[string]methodResponse, len(envelope.MethodResponses))
	for _, raw := range envelope.MethodResponses {
		var tuple []json.RawMessage
		if err := json.Unmarshal(raw, &tuple); err != nil || len(tuple) != 3 {
			return nil, fmt.Errorf("decode JMAP method response")
		}
		var response methodResponse
		if err := json.Unmarshal(tuple[0], &response.Name); err != nil {
			return nil, fmt.Errorf("decode JMAP method name: %w", err)
		}
		response.Args = tuple[1]
		if err := json.Unmarshal(tuple[2], &response.ID); err != nil {
			return nil, fmt.Errorf("decode JMAP call ID: %w", err)
		}
		if response.Name == "error" {
			var callErr jmapError
			_ = json.Unmarshal(response.Args, &callErr)
			if _, alreadySucceeded := responses[response.ID]; alreadySucceeded {
				responses[response.ID+"/implicit-error"] = response
				continue
			}
			if callErr.Description == "" {
				callErr.Description = callErr.Type
			}
			return nil, fmt.Errorf("Fastmail rejected %s: %s", response.ID, callErr.Description)
		}
		if _, exists := responses[response.ID]; exists {
			implicitKey := response.ID + "/implicit"
			if _, duplicate := responses[implicitKey]; duplicate {
				return nil, fmt.Errorf("Fastmail returned multiple implicit responses for %s", response.ID)
			}
			responses[implicitKey] = response
			continue
		}
		responses[response.ID] = response
	}
	return responses, nil
}

func (c *jmapClient) search(ctx context.Context, options searchOptions) ([]emailSummary, int, error) {
	if options.Limit == 0 {
		options.Limit = 20
	}
	if options.Limit < 1 || options.Limit > 100 {
		return nil, 0, fmt.Errorf("limit must be between 1 and 100")
	}
	after, err := normalizeUTCDate("after", options.Filter.After)
	if err != nil {
		return nil, 0, err
	}
	before, err := normalizeUTCDate("before", options.Filter.Before)
	if err != nil {
		return nil, 0, err
	}
	options.Filter.After = after
	options.Filter.Before = before

	session, err := c.getSession(ctx)
	if err != nil {
		return nil, 0, err
	}
	accountID := session.PrimaryAccounts[mailCapability]
	responses, err := c.call(ctx, methodCall{
		Name: "Email/query",
		ID:   "query",
		Args: map[string]any{
			"accountId":      accountID,
			"filter":         options.Filter,
			"sort":           []map[string]any{{"property": "receivedAt", "isAscending": false}},
			"limit":          options.Limit,
			"calculateTotal": true,
		},
	})
	if err != nil {
		return nil, 0, err
	}
	var query emailQueryResponse
	if err := json.Unmarshal(responses["query"].Args, &query); err != nil {
		return nil, 0, fmt.Errorf("decode Email/query: %w", err)
	}
	if len(query.IDs) == 0 {
		return []emailSummary{}, query.Total, nil
	}

	emails, err := c.getEmails(ctx, query.IDs, false)
	if err != nil {
		return nil, 0, err
	}
	result := make([]emailSummary, 0, len(emails))
	for _, email := range emails {
		result = append(result, emailSummary{
			ID:            email.ID,
			ThreadID:      email.ThreadID,
			ReceivedAt:    email.ReceivedAt,
			Subject:       email.Subject,
			From:          email.From,
			To:            email.To,
			Preview:       email.Preview,
			HasAttachment: email.HasAttachment,
			Attachments:   attachmentsFromParts(email.Attachments),
		})
	}
	return result, query.Total, nil
}

func (c *jmapClient) read(ctx context.Context, emailID string) (emailMessage, error) {
	return c.readWithFormat(ctx, emailID, "auto")
}

func (c *jmapClient) readWithFormat(ctx context.Context, emailID, format string) (emailMessage, error) {
	if strings.TrimSpace(emailID) == "" {
		return emailMessage{}, fmt.Errorf("email_id is required")
	}
	emails, err := c.getEmails(ctx, []string{emailID}, true)
	if err != nil {
		return emailMessage{}, err
	}
	if len(emails) != 1 {
		return emailMessage{}, fmt.Errorf("email not found")
	}
	email := emails[0]
	bodyType, body, truncated, err := selectBody(email, format, c.maxBodyBytes)
	if err != nil {
		return emailMessage{}, err
	}
	return emailMessage{
		ID:            email.ID,
		ThreadID:      email.ThreadID,
		ReceivedAt:    email.ReceivedAt,
		Subject:       email.Subject,
		From:          email.From,
		To:            email.To,
		CC:            email.CC,
		BCC:           email.BCC,
		ReplyTo:       email.ReplyTo,
		BodyType:      bodyType,
		Body:          body,
		BodyTruncated: truncated,
		Attachments:   attachmentsFromParts(email.Attachments),
	}, nil
}

func selectBody(email jmapEmail, format string, maxBytes int) (string, string, bool, error) {
	switch format {
	case "auto":
		bodyType, body, truncated := preferredBody(email, maxBytes)
		return bodyType, body, truncated, nil
	case "text":
		if len(email.TextBody) == 0 {
			return "", "", false, fmt.Errorf("email has no plain-text body")
		}
		body, truncated := collectBody(email.TextBody, email.BodyValues, maxBytes)
		return "text/plain", body, truncated, nil
	case "html":
		if len(email.HTMLBody) == 0 {
			return "", "", false, fmt.Errorf("email has no HTML body")
		}
		body, truncated := collectBody(email.HTMLBody, email.BodyValues, maxBytes)
		return "text/html", body, truncated, nil
	default:
		return "", "", false, fmt.Errorf("format must be auto, text, or html")
	}
}

func (c *jmapClient) getEmails(ctx context.Context, ids []string, includeBody bool) ([]jmapEmail, error) {
	session, err := c.getSession(ctx)
	if err != nil {
		return nil, err
	}
	properties := []string{
		"id", "threadId", "receivedAt", "subject", "from", "to", "cc", "bcc",
		"replyTo", "preview", "hasAttachment", "attachments",
	}
	args := map[string]any{
		"accountId":      session.PrimaryAccounts[mailCapability],
		"ids":            ids,
		"properties":     properties,
		"bodyProperties": []string{"partId", "blobId", "type", "name", "size", "disposition"},
	}
	if includeBody {
		args["properties"] = append(properties, "textBody", "htmlBody", "bodyValues")
		args["fetchTextBodyValues"] = true
		args["fetchHTMLBodyValues"] = true
		args["maxBodyValueBytes"] = c.maxBodyBytes
	}
	responses, err := c.call(ctx, methodCall{Name: "Email/get", Args: args, ID: "get"})
	if err != nil {
		return nil, err
	}
	var got emailGetResponse
	if err := json.Unmarshal(responses["get"].Args, &got); err != nil {
		return nil, fmt.Errorf("decode Email/get: %w", err)
	}
	return got.List, nil
}

func preferredBody(email jmapEmail, maxBytes int) (string, string, bool) {
	if body, truncated := collectBody(email.TextBody, email.BodyValues, maxBytes); body != "" {
		return "text/plain", body, truncated
	}
	if body, truncated := collectBody(email.HTMLBody, email.BodyValues, maxBytes); body != "" {
		return "text/html", body, truncated
	}
	return "", "", false
}

func collectBody(parts []jmapPart, values map[string]bodyValue, maxBytes int) (string, bool) {
	var bodies []string
	truncated := false
	for _, part := range parts {
		value, ok := values[part.PartID]
		if !ok || value.Value == "" {
			continue
		}
		bodies = append(bodies, value.Value)
		truncated = truncated || value.IsTruncated
	}
	body := strings.Join(bodies, "\n\n")
	if len(body) > maxBytes {
		body = truncateUTF8(body, maxBytes)
		truncated = true
	}
	return body, truncated
}

func truncateUTF8(value string, maxBytes int) string {
	if maxBytes < 0 {
		return ""
	}
	if len(value) <= maxBytes {
		return value
	}
	value = value[:maxBytes]
	for !utf8.ValidString(value) {
		_, size := utf8.DecodeLastRuneInString(value)
		if size == 0 {
			return ""
		}
		value = value[:len(value)-size]
	}
	return value
}

func attachmentsFromParts(parts []jmapPart) []attachment {
	result := make([]attachment, 0, len(parts))
	for _, part := range parts {
		if part.BlobID == "" {
			continue
		}
		result = append(result, attachment{
			ID:   part.BlobID,
			Name: part.Name,
			Type: part.Type,
			Size: part.Size,
		})
	}
	return result
}

func (c *jmapClient) downloadAttachment(ctx context.Context, emailID, attachmentID string) (string, int64, string, error) {
	if strings.TrimSpace(emailID) == "" || strings.TrimSpace(attachmentID) == "" {
		return "", 0, "", fmt.Errorf("email_id and attachment_id are required")
	}
	emails, err := c.getEmails(ctx, []string{emailID}, false)
	if err != nil {
		return "", 0, "", err
	}
	if len(emails) != 1 {
		return "", 0, "", fmt.Errorf("email not found")
	}
	var selected *jmapPart
	for i := range emails[0].Attachments {
		if emails[0].Attachments[i].BlobID == attachmentID {
			selected = &emails[0].Attachments[i]
			break
		}
	}
	if selected == nil {
		return "", 0, "", fmt.Errorf("attachment does not belong to the specified email")
	}
	if selected.Size > c.maxAttachmentBytes {
		return "", 0, "", fmt.Errorf("attachment exceeds the %d-byte download limit", c.maxAttachmentBytes)
	}

	session, err := c.getSession(ctx)
	if err != nil {
		return "", 0, "", err
	}
	downloadURL := expandDownloadURL(
		session.DownloadURL,
		session.PrimaryAccounts[mailCapability],
		selected.BlobID,
		selected.Name,
		selected.Type,
	)
	if err := c.validateFastmailURL(downloadURL); err != nil {
		return "", 0, "", fmt.Errorf("reject attachment URL: %w", err)
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, downloadURL, nil)
	if err != nil {
		return "", 0, "", fmt.Errorf("create attachment request: %w", err)
	}
	c.authorize(req)
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", 0, "", fmt.Errorf("download attachment: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return "", 0, "", httpStatusError("download attachment", resp)
	}
	if resp.ContentLength > c.maxAttachmentBytes {
		return "", 0, "", fmt.Errorf("attachment exceeds the %d-byte download limit", c.maxAttachmentBytes)
	}

	if err := os.MkdirAll(c.downloadDir, 0o700); err != nil {
		return "", 0, "", fmt.Errorf("create attachment directory: %w", err)
	}
	file, path, err := createUniqueFile(c.downloadDir, sanitizeFilename(selected.Name))
	if err != nil {
		return "", 0, "", err
	}
	keep := false
	defer func() {
		_ = file.Close()
		if !keep {
			_ = os.Remove(path)
		}
	}()

	written, err := io.Copy(file, io.LimitReader(resp.Body, c.maxAttachmentBytes+1))
	if err != nil {
		return "", 0, "", fmt.Errorf("save attachment: %w", err)
	}
	if written > c.maxAttachmentBytes {
		return "", 0, "", fmt.Errorf("attachment exceeds the %d-byte download limit", c.maxAttachmentBytes)
	}
	if err := file.Close(); err != nil {
		return "", 0, "", fmt.Errorf("finish attachment: %w", err)
	}
	keep = true
	return path, written, selected.Type, nil
}

func expandDownloadURL(template, accountID, blobID, name, contentType string) string {
	replacements := map[string]string{
		"{accountId}": url.PathEscape(accountID),
		"{blobId}":    url.PathEscape(blobID),
		"{name}":      url.PathEscape(sanitizeFilename(name)),
		"{type}":      url.QueryEscape(contentType),
	}
	for placeholder, value := range replacements {
		template = strings.ReplaceAll(template, placeholder, value)
	}
	return template
}

func sanitizeFilename(name string) string {
	name = filepath.Base(strings.TrimSpace(name))
	name = strings.Map(func(r rune) rune {
		if unicode.IsControl(r) || r == '/' || r == '\\' || r == ':' {
			return '_'
		}
		return r
	}, name)
	name = strings.Trim(name, ". ")
	if name == "" {
		return "attachment"
	}
	if len(name) > 200 {
		ext := filepath.Ext(name)
		baseLimit := 200 - len(ext)
		if baseLimit < 1 {
			return truncateUTF8(name, 200)
		}
		return truncateUTF8(strings.TrimSuffix(name, ext), baseLimit) + ext
	}
	return name
}

func createUniqueFile(dir, name string) (*os.File, string, error) {
	ext := filepath.Ext(name)
	base := strings.TrimSuffix(name, ext)
	for i := 0; i < 1000; i++ {
		candidate := name
		if i > 0 {
			candidate = fmt.Sprintf("%s (%d)%s", base, i, ext)
		}
		path := filepath.Join(dir, candidate)
		file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o600)
		if err == nil {
			return file, path, nil
		}
		if !errors.Is(err, os.ErrExist) {
			return nil, "", fmt.Errorf("create attachment file: %w", err)
		}
	}
	return nil, "", fmt.Errorf("could not choose a unique attachment filename")
}

func normalizeUTCDate(field, value string) (string, error) {
	if value == "" {
		return "", nil
	}
	parsed, err := time.Parse(time.RFC3339, value)
	if err != nil {
		return "", fmt.Errorf("%s must be an RFC3339 timestamp", field)
	}
	return parsed.UTC().Format(time.RFC3339Nano), nil
}

func decodeLimitedJSON(reader io.Reader, target any) error {
	return json.NewDecoder(io.LimitReader(reader, 10*1024*1024)).Decode(target)
}

func httpStatusError(action string, resp *http.Response) error {
	message, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
	clean := strings.TrimSpace(string(message))
	if clean == "" {
		return fmt.Errorf("%s: Fastmail returned HTTP %d", action, resp.StatusCode)
	}
	return fmt.Errorf("%s: Fastmail returned HTTP %d: %s", action, resp.StatusCode, clean)
}
