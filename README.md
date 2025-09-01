### NAME

    git_fix_merge_rebase.sh

### SYNOPSIS

    git_fix_merge_rebase.sh [ -l | --loosen ]
        [ --ca | --common-ansestor ] [ -d | --delim ] 
        [ --dr | --dry-run ] [ -v | --verbose ]
        [ -p | --progress ] [ --pt | --preserve-tmp ] <Bad Branch/Tag/commit>
        
### DESCRIPTION

    Fixes duplicate commits when mixing merges and rebases on team branches.

### Options
	-l, --loosen
        Loosen the commit matching.  Can specify multiple times to make it more forgiving on matches.  Useful when commit messages don't match due to edits during rebasing.

    --ca, --common-ansestor (Default)
        Use merge-base to determine common ansestor. Speeds up finding missing/duplicate commits, but slightly possible to miss commits.
    
    ---no-ca, --no-common-ansestor
        Disables common-ansestor. Slower, but possibly more accurate.

    -d, --delim (Default: |)
        Change delimiter. Must be a printable character.

    --dr, --dry-run
        Dry run.  Emits the cherry-pick command to be run, and does NOT run the command.

    --no-dr, --no-dry-run (Default)
        Does the run.

    -v, --verbose
        Verbose output.

    --no-verbose (Default)
        Disable verbose output.
        
    -p, --progress (Default)
        Progress output.

    --no-progress
        Disables progress output.

    --pt, --preserve-tmp
        Preserves the temporary directory. Could be useful for debuging.

    --no-pt, --no-preserve-tmp (Default)
        Deletes temporary directory.

### Usage

    1) Create a clean branch based on the base/team branch
    2) Run git_fix_merge_rebase.sh
