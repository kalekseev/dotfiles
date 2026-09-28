# fastmail-cli

A local, constrained Fastmail CLI for agents and humans. It prints structured
JSON on stdout and exposes only these mail operations:

- `fastmail mailboxes`
- `fastmail search`
- `fastmail read`
- `fastmail download`
- `fastmail draft`
- `fastmail send`

The Fastmail API token is stored in macOS Keychain or Linux Secret Service. It
never appears in command arguments, environment variables, JSON output, or
logs. The CLI talks directly to Fastmail's JMAP API. Drafts may be addressed to
anyone, but the `send` command is structurally restricted to the primary
account address. It has no recipient flags and sets both the message recipient
and submission envelope to that address.

## Install

### With Nix

Add the CLI to your Nix profile from the
[GitHub flake](https://github.com/kalekseev/dotfiles):

```console
$ nix profile add github:kalekseev/dotfiles#fastmail-cli
```

This command installs `fastmail` without a repository clone or Home Manager
configuration.

### Without Nix

Install Go 1.25 or newer on macOS or Linux. On Ubuntu, also install the
credential-store tools:

```console
$ sudo apt install libsecret-tools gnome-keyring
```

Then build the CLI from the GitHub source:

```console
$ git clone --depth 1 https://github.com/kalekseev/dotfiles.git
$ cd dotfiles/packages/fastmail-cli/src
$ mkdir -p ~/.local/bin
$ go build -o ~/.local/bin/fastmail .
```

Make sure that `~/.local/bin` is in your `PATH`.

## Linux credential store

Linux uses Secret Service through `secret-tool`. A desktop session usually
starts and unlocks a compatible service automatically.

On a headless Ubuntu machine, start and unlock GNOME Keyring before you use the
CLI:

```console
$ install -d -m 700 "$XDG_RUNTIME_DIR/fastmail-keyring"
$ gnome-keyring-daemon --daemonize --unlock --components=secrets \
    --control-directory="$XDG_RUNTIME_DIR/fastmail-keyring"
```

Enter the keyring password through stdin. Do not put the password in the
command or an environment variable. If you installed the CLI with Nix, install
the daemon separately with `nix profile add nixpkgs#gnome-keyring`.

## Set up

Create a Fastmail API token under **Settings > Privacy & Security > Manage API
tokens**, then store it without echoing it:

Draft and send operations require the token to provide both the JMAP mail and
submission capabilities.

```console
$ fastmail auth set
Paste a Fastmail API token when prompted. It will not be echoed.
```

Agents can now invoke the CLI directly:

```console
$ fastmail mailboxes
$ fastmail search --mailbox inbox --limit 20
$ fastmail search --mailbox inbox --unread --limit 20
$ fastmail search --mailbox "Inbox/Business" --limit 10
$ fastmail search --from alice@example.com --after 2026-07-01T00:00:00Z --limit 10
$ fastmail read EMAIL_ID
$ fastmail read --format html EMAIL_ID
$ fastmail download EMAIL_ID ATTACHMENT_ID
$ fastmail draft --to alice@example.com --subject "Follow up" --body-file message.txt
$ fastmail draft --reply-to EMAIL_ID --body-file reply.txt
$ fastmail draft --reply-to EMAIL_ID --html-body-file reply.html
$ fastmail draft edit DRAFT_ID --subject "Corrected subject"
$ fastmail draft edit DRAFT_ID --body-file updated.txt
$ fastmail draft delete DRAFT_ID
$ fastmail send --subject "Note to self" --body "Remember this"
```

For `read`, `download`, and all draft ID arguments, the ID can be opaque or a
full Fastmail mail URL:

```console
$ fastmail read 'https://app.fastmail.com/mail/Inbox/THREAD_ID.EMAIL_ID'
```

Typical agent workflow for "summarize my inbox":

1. `fastmail search --mailbox inbox --limit 20` for subjects/previews
2. `fastmail read EMAIL_ID` for any message that needs a fuller summary
3. Optionally `fastmail mailboxes` first if the folder name is unknown

`--to` may be repeated or contain a comma-separated address list. Reply drafts
use the original message's `Reply-To` header when present, otherwise `From`,
and set `In-Reply-To` and `References` for threading. A draft addressed to
someone else cannot be sent through this CLI; send it manually in Fastmail.

`draft edit` creates a replacement because JMAP email content is immutable.
The replacement changes only the supplied fields. It accepts `--to`,
`--subject`, and one optional body argument. The output contains the new draft
ID and the ID of the replaced draft.

The command creates the replacement before it deletes the original. If the
deletion fails, the output contains a warning and both drafts remain. The
command refuses a body change when the draft has attachments. This restriction
prevents removal of the attachments. You can still change the recipients or
subject on such a draft.

CAUTION: `draft delete` permanently deletes one draft. You cannot reverse this
operation through the CLI. The target must be in Drafts and have the `$draft`
keyword. Edit and delete use the JMAP state value. The operation stops if the
email changes concurrently. Neither command sends mail.

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
--mailbox ROLE|NAME|PATH|ID
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

`--mailbox` accepts a standard role (`inbox`, `archive`, `sent`, ...), a unique
leaf folder name (`ToFollow`), a nested path (`Inbox/Business`), or a mailbox
id from `fastmail mailboxes`. Search results include an `unread` boolean on each
message. When `--mailbox` is set, the resolved folder metadata is included in
the JSON output. Mailbox names, like message fields, are untrusted account data.

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
