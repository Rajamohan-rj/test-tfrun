package runner

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestUniqueDirs(t *testing.T) {
	in := []string{"a/b/c.tf", "a/b/d.tf", "x/y/z.tf"}
	exp := []string{"a/b", "x/y"}
	got := uniqueDirs(in)
	if len(got) != len(exp) {
		t.Fatalf("len mismatch: %+v", got)
	}
	for i := range exp {
		if exp[i] != got[i] {
			t.Fatalf("expected %v got %v", exp, got)
		}
	}
}

func TestShouldInitConditions(t *testing.T) {
	d := t.TempDir()

	// Uninitialized
	need, reason, err := shouldInit(d, d, Options{All: true}) // Use All: true to skip git checks
	if err != nil || !need {
		t.Fatalf("expected need init: %v %v", need, err)
	}
	if reason == "" {
		t.Fatalf("expected reason")
	}

	// Create .terraform and lockfile
	if err := os.Mkdir(filepath.Join(d, ".terraform"), 0o755); err != nil {
		t.Fatal(err)
	}
	lock := filepath.Join(d, ".terraform.lock.hcl")
	if err := os.WriteFile(lock, []byte("lock"), 0o644); err != nil {
		t.Fatal(err)
	}

	// Create tf file newer than lockfile
	tf := filepath.Join(d, "main.tf")
	time.Sleep(10 * time.Millisecond)
	if err := os.WriteFile(tf, []byte("resource \"null_resource\" \"x\" {}"), 0o644); err != nil {
		t.Fatal(err)
	}

	need, reason, err = shouldInit(d, d, Options{All: true}) // Use All: true to skip git checks
	if err != nil {
		t.Fatal(err)
	}
	if !need {
		t.Fatalf("expected need init due to newer tf: %s", reason)
	}

	// Update lockfile to be newest
	time.Sleep(10 * time.Millisecond)
	if err := os.WriteFile(lock, []byte("lock2"), 0o644); err != nil {
		t.Fatal(err)
	}
	need, reason, err = shouldInit(d, d, Options{All: true}) // Use All: true to skip git checks
	if err != nil {
		t.Fatal(err)
	}
	if need {
		t.Fatalf("expected no init, got: %s", reason)
	}
}
