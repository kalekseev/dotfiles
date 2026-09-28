//go:build linux

package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func installFakeSecretTool(t *testing.T) (string, string) {
	t.Helper()
	directory := t.TempDir()
	program := filepath.Join(directory, "secret-tool")
	argsPath := filepath.Join(directory, "args")
	stdinPath := filepath.Join(directory, "stdin")
	script := `#!/bin/sh
printf '%s\n' "$@" > "$FASTMAIL_SECRET_TOOL_ARGS"
if [ "$FASTMAIL_SECRET_TOOL_FAIL" = "1" ]; then
  echo "Secret Service is unavailable" >&2
  exit 1
fi
case "$1" in
  lookup) printf '%s\n' "$FASTMAIL_SECRET_TOOL_VALUE" ;;
  store) cat > "$FASTMAIL_SECRET_TOOL_STDIN" ;;
esac
`
	if err := os.WriteFile(program, []byte(script), 0o700); err != nil {
		t.Fatal(err)
	}
	previousProgram := credentialStoreProgram
	credentialStoreProgram = program
	t.Cleanup(func() { credentialStoreProgram = previousProgram })
	t.Setenv("FASTMAIL_SECRET_TOOL_ARGS", argsPath)
	t.Setenv("FASTMAIL_SECRET_TOOL_STDIN", stdinPath)
	return argsPath, stdinPath
}

func TestReadTokenFromSecretService(t *testing.T) {
	argsPath, _ := installFakeSecretTool(t)
	t.Setenv("FASTMAIL_SECRET_TOOL_VALUE", "test-token")

	token, err := readTokenFromCredentialStore()
	if err != nil {
		t.Fatal(err)
	}
	if token != "test-token" {
		t.Fatalf("unexpected token: %q", token)
	}
	args, err := os.ReadFile(argsPath)
	if err != nil {
		t.Fatal(err)
	}
	for _, value := range []string{"lookup", "service", credentialStoreService, "account"} {
		if !strings.Contains(string(args), value+"\n") {
			t.Errorf("secret-tool arguments do not contain %q: %s", value, args)
		}
	}
	if strings.Contains(string(args), token) {
		t.Fatal("the token was passed as a command argument")
	}
}

func TestStoreTokenInSecretServiceUsesStdin(t *testing.T) {
	argsPath, stdinPath := installFakeSecretTool(t)
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	if err := setTokenInCredentialStore(
		strings.NewReader("test-token\n"),
		&stdout,
		&stderr,
	); err != nil {
		t.Fatal(err)
	}
	stored, err := os.ReadFile(stdinPath)
	if err != nil {
		t.Fatal(err)
	}
	if string(stored) != "test-token\n" {
		t.Fatalf("unexpected stored token: %q", stored)
	}
	args, err := os.ReadFile(argsPath)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(args), "store\n") || strings.Contains(string(args), "test-token") {
		t.Fatalf("unexpected secret-tool arguments: %s", args)
	}
}

func TestSecretServiceFailureIncludesDiagnostic(t *testing.T) {
	installFakeSecretTool(t)
	t.Setenv("FASTMAIL_SECRET_TOOL_FAIL", "1")

	_, err := readTokenFromCredentialStore()
	if err == nil || !strings.Contains(err.Error(), "Secret Service is unavailable") {
		t.Fatalf("unexpected error: %v", err)
	}
	if tokenExistsInCredentialStore() {
		t.Fatal("credential unexpectedly exists after a Secret Service failure")
	}
}
