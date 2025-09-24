package tfrun

import (
	"fmt"
	"os"

	"tfrun/internal/runner"
	"github.com/spf13/cobra"
)

var (
	version = "dev"
	commit  = "none"
	date    = "unknown"
	opts    runner.Options
)

var rootCmd = &cobra.Command{
	Use:   "tfrun",
	Short: "Git-aware Terraform runner",
	Long:  `tfrun is a tool to run terraform commands on files changed in git.`,
	Args:  cobra.NoArgs, // <-- Add this line to reject extra arguments
	Run: func(cmd *cobra.Command, args []string) {
		if err := runner.Run(opts); err != nil {
			fmt.Fprintln(os.Stderr, "Error:", err)
			os.Exit(1)
		}
	},
}

func init() {
	rootCmd.Flags().BoolVar(&opts.Staged, "staged", false, "use staged changes (git diff --cached)")
	rootCmd.Flags().StringVar(&opts.Against, "against", "", "compare against a git ref (git diff <ref> --name-only)")
	rootCmd.Flags().BoolVar(&opts.All, "all", false, "consider all tracked .tf files (ignores git diff filtering)")
	rootCmd.Flags().BoolVar(&opts.ForceInit, "force-init", false, "always run terraform init (implies upgrade unless --no-upgrade)")
	rootCmd.Flags().BoolVar(&opts.NoUpgrade, "no-upgrade", false, "when running init, do not pass -upgrade")
	rootCmd.Flags().BoolVar(&opts.DryRun, "dry-run", false, "print actions without executing terraform")
	rootCmd.Flags().BoolVar(&opts.Verbose, "verbose", false, "verbose logging")
	rootCmd.Flags().Bool("version", false, "print version")

	rootCmd.PreRun = func(cmd *cobra.Command, args []string) {
		showVersion, _ := cmd.Flags().GetBool("version")
		if showVersion {
			fmt.Printf("tf-run %s (commit %s, built %s)\n", version, commit, date)
			os.Exit(0)
		}
	}
}

// Execute runs the root command - called from main.go
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
