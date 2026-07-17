package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"os/user"
	"strings"
)

const (
	keychainProgram = "/usr/bin/security"
	keychainService = "fastmail-cli"
)

func keychainAccount() (string, error) {
	current, err := user.Current()
	if err != nil {
		return "", fmt.Errorf("determine Keychain account: %w", err)
	}
	if current.Username == "" {
		return "", fmt.Errorf("determine Keychain account: empty OS username")
	}
	return current.Username, nil
}

func readTokenFromKeychain() (string, error) {
	account, err := keychainAccount()
	if err != nil {
		return "", err
	}

	cmd := exec.Command(
		keychainProgram,
		"find-generic-password",
		"-a", account,
		"-s", keychainService,
		"-w",
	)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf(
			"read Fastmail token from Keychain: %s (run `fastmail auth set`)",
			strings.TrimSpace(stderr.String()),
		)
	}

	token := strings.TrimSpace(string(output))
	if token == "" {
		return "", fmt.Errorf("read Fastmail token from Keychain: stored value is empty")
	}
	return token, nil
}

func setTokenInKeychain() error {
	account, err := keychainAccount()
	if err != nil {
		return err
	}

	cmd := exec.Command(
		keychainProgram,
		"add-generic-password",
		"-U",
		"-a", account,
		"-s", keychainService,
		"-D", "Fastmail API token",
		"-j", "Read-only token used by the fastmail CLI",
		"-w", // Last means security(1) prompts without echoing the password.
	)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("store Fastmail token in Keychain: %w", err)
	}
	return nil
}

func tokenExistsInKeychain() bool {
	account, err := keychainAccount()
	if err != nil {
		return false
	}
	cmd := exec.Command(
		keychainProgram,
		"find-generic-password",
		"-a", account,
		"-s", keychainService,
	)
	cmd.Stdout = nil
	cmd.Stderr = nil
	return cmd.Run() == nil
}
