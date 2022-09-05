#!/usr/bin/env bash

# Creates a new release branch based on provided sha and commit titles.
#
# Reads lines containing repo and sha from a file.
#
# If the last release branch is an ancestor of the sha, analyze the commit
# titles and bump the semantic version as appropriate.
#
# Only commit titles starting with the following strings are considered:
#
#   [breaking] = Increment major version.
#   [feature]  = Increment minor version.
#   [bugfix]   = Increment patch version.

# The format of each line in the file is: REPO_URL RELEASE_SHA
# Blank lines and lines beginning with '#' are ignored.

readonly REPO_LIST='config/list.txt'

echo "############################################################"
date
echo "############################################################"
echo

if [ ! -f "$REPO_LIST" ]; then
  echo "Missing file: $REPO_LIST"
  exit 1
fi

mkdir -p tmp/dest

checkout_and_push () {
  echo
  echo "git co -b $1 $2"
  git co -b $1 $2

  echo "git push origin $1"
  git push origin $1
}

process_file () {
  local readonly f=$1
  cat $f  \
    | egrep -v '^#|^\s*$'
}

main () {
  process_file $REPO_LIST \
  | while read -r repo_url sha; do
      echo "------------------------------------------------------------"
      echo "Checking $repo_url" "$sha"

      # Make a fresh clone each time.
      clone_dir="tmp/dest/$(basename $repo_url)"
      rm -rf $clone_dir
      git clone --quiet $repo_url $clone_dir

      (
        cd $clone_dir

        # https://exchangetuts.com/how-to-sort-semantic-versions-in-bash-1639819027918590
        last_release=$(git branch -a  --list '*/release/[0-9]*' \
          | sed -e 's|\s*||' \
          | cut -d+ -f1 \
          | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$//' \
          | tail -1)

        if [ -z "$last_release" ]; then
          echo "No release branches found."
        else
          echo "Found release: $last_release"

          if git merge-base --is-ancestor $last_release $sha; then
            echo
            echo "New commits:"
            git log --oneline ^$last_release $sha --grep '^\[breaking\]'  --grep '^\[feature\]'  --grep '^\[bugfix\]'

            if [ $(git log --oneline ^$last_release $sha --grep '^\[breaking\]' | wc -l) -ne "0" ]; then
              n=${last_release//[!0-9]/ }
              a=(${n//\./ })
              new_release="release/$((${a[0]}+1)).0.0"

              checkout_and_push $new_release $sha

              exit 0
            fi

            if [ $(git log --oneline ^$last_release $sha --grep '^\[feature\]' | wc -l) -ne "0" ]; then
              n=${last_release//[!0-9]/ }
              a=(${n//\./ })
              new_release="release/${a[0]}.$((${a[1]}+1)).0"

              checkout_and_push $new_release $sha

              exit 0
            fi

            if [ $(git log --oneline ^$last_release $sha --grep '^\[bugfix\]' | wc -l) -ne "0" ]; then
              n=${last_release//[!0-9]/ }
              a=(${n//\./ })
              new_release="release/${a[0]}.${a[1]}.$((${a[2]}+1))"

              checkout_and_push $new_release $sha

              exit 0
            fi

            echo
            echo "Nothing to release since $last_release"

            exit 1
          else
            echo "$sha is NOT an ancestor of $last_release. Skipping."
            exit 1
          fi
        fi
      )

      echo
    done
}

main
