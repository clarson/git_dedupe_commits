#/bin/bash

function print_verbose()
{
	if [ "$VERBOSE" != "1" ]
	then
		return
	fi
	echo $*
}

function print_progress()
{
	if [ "$PROGRESS" != "1" ]
	then
		return
	fi
	echo $*
}

function git_log()
{
	git log --no-merges --pretty=format:"$PFORMAT" --date=unix "$1" |sort
}

PRESERVE_TMP=0
USE_COMMON=1
DRY_RUN=0
PROGRESS=1
VERBOSE=0
STRICTNESS=6
DELIM="|"
BRANCHES=()
BRANCH_BAD=
while [ "$1" != "" ]
do
	ORIG=$1
	OPT=$ORIG
	shift
	VAL=1
	if [[ "$OPT" =~ ^--no- ]]
	then
		VAL=0
		OPT="${OPT//--no-/--}"
	fi

	case "$OPT" in
		"--pt" | "--preserve-tmp")
			PRESERVE_TMP=$VAL
			;;
		"--ca" | "--common-ansestor")
			USE_COMMON=$VAL
			;;
		"-l" | "--loosen")
			if [ "$STRICTNESS" -lt 4 ]
			then
				echo Too many loosen options specified
				exit 1
			fi
			STRICTNESS=$(($STRICTNESS - 1))
			;;
		"-d" | "--delim")
			DELIM=$1
			shift
			if [ ${#DELIM} -ne 1 ]
			then
				echo $DELIM '(Delimiter)' must be 1 character only
				exit 1
			fi
			;;
		"--dr" | "--dry-run")
			DRY_RUN=$VAL
			;;
		"-v" | "--verbose")
			VERBOSE=$VAL
			;;
		"-p" | "--progress")
			PROGRESS=$VAL
			;;
		*)
			if [[ "$OPT" =~ ^- ]]
			then
				echo Unknown option $ORIG
				exit 1
			else
				if [ "$BRANCH_BAD" != "" ]
				then
					echo Bad branch specified twice
					exit 1
				fi
				BRANCH_BAD=$OPT
			fi
			;;
	esac
done

if [ "$BRANCH_BAD" = "" ]
then
	echo Bad branch required
	exit 1
fi

PFORMAT="%cd$DELIM%h$DELIM%ad$DELIM%an$DELIM%ae$DELIM%s$DELIM%N"
# Column 1: cd - committer date
# Column 2: h  - HASH
# Column 3: ad - Author date
# Column 4: an - Author Name
# Column 5: ae - Author Email
# Column 5: s  - Subject
# Column 6: N  - Notes

TDIR=$(mktemp -d)

if [ "$PRESERVE_TMP" = "0" ]
then
	trap 'rm -r $TDIR' EXIT
fi

if [ "$USE_COMMON" = "1" ]
then
	COMMON=$(git merge-base "HEAD" "$BRANCH_BAD")

	if [ "$COMMON" = "" ]
	then
		echo No common ancestor.
		echo If this is expected, pass --no-common-ansestor to skip this option
		echo exiting.
		exit 1
	fi
	COMMON+=".."
fi

git_log "${COMMON}HEAD" > "$TDIR/branch_a.txt" || exit 1

git_log "$COMMON$BRANCH_BAD" > "$TDIR/branch_b.txt" || exit 1

cp "$TDIR/branch_a.txt" "$TDIR/branch_c.txt" || exit 1

COMMITS=()
while read line
do
	HASH=$(echo $line | cut -d "$DELIM" -f2)
	if grep -q "|$HASH|" $TDIR/branch_c.txt
	then
		print_progress -n .
		continue
	fi
	
	REST=$(echo $line | cut -d "$DELIM" -f3-$STRICTNESS)
	if grep -q "|$REST" $TDIR/branch_c.txt
	then
		print_progress -n .
		continue
	fi
	
	echo $line >> $TDIR/branch_c.txt
	print_progress -n F
	
	COMMITS+=($HASH)
done < $TDIR/branch_b.txt

print_progress

if [ ${#COMMITS[@]} -le 0 ]
then
	echo no commits found
	exit 1
fi

echo Commits found: ${#COMMITS[@]}

if [ "$DRY_RUN" = "1" ]
then
	echo git cherry-pick ${COMMITS[*]}
	exit 0
fi

git cherry-pick ${COMMITS[*]}
