# fastmail-cli

A local, constrained Fastmail CLI for agents and humans. It prints structured
JSON on stdout and exposes only these mail operations:

- `fastmail search`
- `fastmail read`
- `fastmail download`
- `fastmail draft`
- `fastmail send`

The Fastmail API token is stored in macOS Keychain and never appears in command
arguments, environment variables, JSON output, or logs. The CLI talks directly
to Fastmail's JMAP API. Drafts may be addressed to anyone, but the `send`
command is structurally restricted to the primary account address: it has no
recipient flags and sets both the message recipient and submission envelope to
that address.

## Set up

Create a Fastmail API token under **Settings > Privacy & Security > Manage API
tokens**, then store it without echoing it:

Draft and send operations require the token to provide both the JMAP mail and
submission capabilities.

```console
$ nix run .#fastmail-cli -- auth set
Paste a Fastmail API token when prompted. It will not be echoed.
password data for new item:
```

After installing the package through Home Manager, agents can invoke the
normal CLI directly:

```console
$ fastmail search --from alice@example.com --after 2026-07-01T00:00:00Z --limit 10
$ fastmail search --unread --limit 20
$ fastmail read EMAIL_ID
$ fastmail read --format html EMAIL_ID
$ fastmail download EMAIL_ID ATTACHMENT_ID
$ fastmail draft --to alice@example.com --subject "Follow up" --body-file message.txt
$ fastmail draft --reply-to EMAIL_ID --body-file reply.txt
$ fastmail draft --reply-to EMAIL_ID --html-body-file reply.html
$ fastmail send --subject "Note to self" --body "Remember this"
```

`--to` may be repeated or contain a comma-separated address list. Reply drafts
use the original message's `Reply-To` header when present, otherwise `From`,
and set `In-Reply-To` and `References` for threading. A draft addressed to
someone else cannot be sent through this CLI; send it manually in Fastmail.

Both `draft` and `send` require exactly one body option:

```text
--body TEXT
--body-file PATH
--html-body HTML
--html-body-file PATH
```

Use either file option with `-` to read from stdin. Plain-text options create a
plain message. HTML options create a `multipart/alternative` message containing
both the rich HTML and an automatically generated plain-text fallback. An HTML
fragment is wrapped in a minimal document; a complete document containing an
`<html>` element is preserved.

Fastmail's normal rich-text editor uses simple HTML with `<div>` paragraphs and
`<div><br></div>` blank lines. For example:

```console
$ fastmail draft --to alice@example.com --subject "Follow up" \
    --html-body '<div>Hi Alice,</div><div><br></div><div>The <strong>updated proposal</strong> is attached.</div><div><br></div><div>Best regards,</div><div>Konstantin</div>'
```

The CLI does not add a signature automatically, so the caller remains in
control of the sign-off.

Search options:

```text
--query TEXT
--from TEXT
--to TEXT
--subject TEXT
--after RFC3339
--before RFC3339
--unread
--has-attachment=true|false
--limit 1..100
```

Email and attachment outputs contain an explicit `untrusted_content` or
`untrusted_file` marker so an agent can distinguish mailbox data from trusted
instructions.

Attachments are written with mode `0600` below `~/Downloads/Fastmail`. Set
`FASTMAIL_DOWNLOAD_DIR` in the process environment to choose a different
fixed directory. The caller cannot supply a destination path. Downloads are
limited to 25 MiB by default; override the positive byte limit with
`FASTMAIL_MAX_ATTACHMENT_BYTES`.

This hides the credential from ordinary CLI invocations. An agent with
unrestricted command execution as the same macOS user may still be able to
invoke Keychain-authorized programs, so use a separate OS account or sandbox
if that stronger threat model matters.
