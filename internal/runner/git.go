package runner

import (
	"bytes"
	"os/exec"
	"path/filepath"
	"strings"
)

func gitRepoRoot() (string, error) {
	out, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}

func gitDiffTfFiles(repoRoot string, staged, againstSet bool, against string) ([]string, error) {
	args := []string{"diff", "--name-only"}
	if staged {
		args = append(args, "--cached")
	}
	if againstSet {
		args = []string{"diff", against, "--name-only"}
	}
	cmd := exec.Command("git", args...)
	cmd.Dir = repoRoot
	var b bytes.Buffer
	cmd.Stdout = &b
	if err := cmd.Run(); err != nil {
		return nil, err
	}
	lines := strings.Split(strings.TrimSpace(b.String()), "\n")
	var out []string
	for _, l := range lines {
		if strings.HasSuffix(l, ".tf") {
			out = append(out, filepath.ToSlash(l))
		}
	}
	return out, nil
}

func gitListAllTrackedTf(repoRoot string) ([]string, error) {
	cmd := exec.Command("git", "ls-files", "*.tf")
	cmd.Dir = repoRoot
	var b bytes.Buffer
	cmd.Stdout = &b
	if err := cmd.Run(); err != nil {
		return nil, err
	}
	lines := strings.Split(strings.TrimSpace(b.String()), "\n")
	var out []string
	for _, l := range lines {
		if strings.TrimSpace(l) == "" {
			continue
		}
		out = append(out, l)
	}
	return out, nil
}

func gitLockfileChanged(repoRoot string, staged, againstSet bool, against, dir string) (bool, error) {
	args := []string{"diff", "--name-only"}
	if staged {
		args = append(args, "--cached")
	}
	if againstSet {
		args = []string{"diff", against, "--name-only"}
	}
	cmd := exec.Command("git", args...)
	cmd.Dir = repoRoot
	var b bytes.Buffer
	cmd.Stdout = &b
	if err := cmd.Run(); err != nil {
		return false, err
	}
	for _, l := range strings.Split(strings.TrimSpace(b.String()), "\n") {
		l = strings.TrimSpace(l)
		if l == "" {
			continue
		}
		if filepath.ToSlash(l) == filepath.ToSlash(filepath.Join(dir, ".terraform.lock.hcl")) {
			return true, nil
		}
	}
	return false, nil
}
