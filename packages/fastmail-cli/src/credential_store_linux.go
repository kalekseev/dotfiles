//go:build linux

package main

import (
	"bytes"
	"fmt"
	"io"
	"os/exec"
	"os/user"
	"strings"
)

const (
	credentialStoreName    = "Secret Service"
	credentialStoreService = "fastmail-cli"
)

var credentialStoreProgram = "secret-tool"

func credentialStoreAccount() (string, error) {
	current, err := user.Current()
	if err != nil {
		return "", fmt.Errorf("determine credential-store account: %w", err)
	}
	if current.Username == "" {
		return "", fmt.Errorf("determine credential-store account: empty OS username")
	}
	return current.Username, nil
}

func readTokenFromCredentialStore() (string, error) {
	account, err := credentialStoreAccount()
	if err != nil {
		return "", err
	}

	cmd := exec.Command(
		credentialStoreProgram,
		"lookup",
		"service", credentialStoreService,
		"account", account,
	)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	output, err := cmd.Output()
	if err != nil {
		detail := strings.TrimSpace(stderr.String())
		if detail == "" {
			detail = err.Error()
		}
		return "", fmt.Errorf(
			"read Fastmail token from Secret Service: %s (run `fastmail auth set`)",
			detail,
		)
	}

	token := strings.TrimSpace(string(output))
	if token == "" {
		return "", fmt.Errorf("read Fastmail token from Secret Service: stored value is empty")
	}
	return token, nil
}

func setTokenInCredentialStore(stdin io.Reader, stdout, stderr io.Writer) error {
	account, err := credentialStoreAccount()
	if err != nil {
		return err
	}

	cmd := exec.Command(
		credentialStoreProgram,
		"store",
		"--label=Fastmail API token",
		"service", credentialStoreService,
		"account", account,
	)
	cmd.Stdin = stdin
	cmd.Stdout = stdout
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("store Fastmail token in Secret Service: %w", err)
	}
	return nil
}

func tokenExistsInCredentialStore() bool {
	account, err := credentialStoreAccount()
	if err != nil {
		return false
	}
	cmd := exec.Command(
		credentialStoreProgram,
		"lookup",
		"service", credentialStoreService,
		"account", account,
	)
	cmd.Stdout = nil
	cmd.Stderr = nil
	return cmd.Run() == nil
}
