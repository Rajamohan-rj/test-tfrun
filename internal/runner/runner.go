package runner

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

type Options struct {
	Staged    bool
	againstSet bool
	Against   string
	All       bool
	ForceInit bool
	NoUpgrade bool
	DryRun    bool
	Verbose   bool
}

func (o *Options) init() {
	o.againstSet = o.Against != ""
}

func Run(opts Options) error {
	opts.init()

	repoRoot, err := gitRepoRoot()
	if err != nil {
		return fmt.Errorf("not a git repo? %w", err)
	}
	log(opts, "Repository root: %s", repoRoot)

	var files []string
	if opts.All {
		files, err = gitListAllTrackedTf(repoRoot)
	} else {
		files, err = gitDiffTfFiles(repoRoot, opts.Staged, opts.againstSet, opts.Against)
	}
	if err != nil {
		return err
	}

	dirs := uniqueDirs(files)
	if len(dirs) == 0 {
		log(opts, "No matching Terraform directories found.")
		return nil
	}

	for _, dir := range dirs {
		abs := filepath.Join(repoRoot, dir)
		fmt.Printf("=== Processing: %s ===\n", dir)
		needInit, reason, err := shouldInit(abs, repoRoot, opts)
		if err != nil {
			return err
		}
		if needInit || opts.ForceInit {
			args := []string{"init"}
			if !opts.NoUpgrade { args = append(args, "-upgrade") }
			if err := runTerraform(abs, opts, args...); err != nil {
				return err
			}
			if needInit {
				log(opts, "init condition: %s", reason)
			} else {
				log(opts, "forced init")
			}
		} else {
			log(opts, "Skipping init (%s)", reason)
		}
		if err := runTerraform(abs, opts, "plan"); err != nil {
			return err
		}
	}
	return nil
}

func uniqueDirs(files []string) []string {
	m := map[string]struct{}{}
	for _, f := range files {
		d := filepath.Dir(f)
		m[d] = struct{}{}
	}
	out := make([]string, 0, len(m))
	for d := range m { out = append(out, d) }
	sort.Strings(out)
	return out
}

func log(opts Options, fmtStr string, a ...any) {
	if opts.Verbose {
		fmt.Printf(fmtStr+"\n", a...)
	}
}

func runTerraform(dir string, opts Options, args ...string) error {
	cmd := exec.Command("terraform", args...)
	cmd.Dir = dir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if opts.DryRun {
		fmt.Printf("[dry-run] (cd %s && terraform %s)\n", dir, strings.Join(args, " "))
		return nil
	}
	return cmd.Run()
}

func shouldInit(dir, repoRoot string, opts Options) (bool, string, error) {
	terraformDir := filepath.Join(dir, ".terraform")
	lockFile := filepath.Join(dir, ".terraform.lock.hcl")

	// If .terraform missing
	if _, err := os.Stat(terraformDir); os.IsNotExist(err) {
		return true, ".terraform missing", nil
	}

	// If lockfile missing
	lockStat, err := os.Stat(lockFile)
	if os.IsNotExist(err) {
		return true, "lockfile missing", nil
	}
	if err != nil {
		return false, "", err
	}

	// If lockfile is older than latest *.tf in dir
	latestTf := time.Unix(0, 0)
	err = filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil { return err }
		if info.IsDir() { return nil }
		if strings.HasSuffix(path, ".tf") {
			if info.ModTime().After(latestTf) {
				latestTf = info.ModTime()
			}
		}
		return nil
	})
	if err != nil { return false, "", err }

	if lockStat.ModTime().Before(latestTf) {
		return true, "lockfile older than *.tf", nil
	}

	// If lockfile appears modified in diff (when not --all)
	if !opts.All {
		changed, err := gitLockfileChanged(repoRoot, opts.Staged, opts.againstSet, opts.Against, dir)
		if err != nil { return false, "", err }
		if changed {
			return true, ".terraform.lock.hcl changed in diff", nil
		}
	}

	return false, "already initialized and lockfile fresh", nil
}
