# cut-release

This program takes a list of github url's and commits to base a new
release on.

Release branches are named as per the [requirements](REQUIREMENTS.md).

If the commit is a descendent of the last release branch, the commit
titles are examined to determine what the new semantic version will
be. After calculating the new release version, a new release branch is
created and pushed to the origin.

Commit titles must begin with one of the following to cause a new release
number to be calculated. At least one matching title must be present in
the list of commits from the previous release to the specified commit.

  - [breaking] = Increment major version.
  - [feature]  = Increment minor version.
  - [bugfix]   = Increment patch version.

### Setup

For testing, it's recommended to clone an existing repo for safety. Create
a `tmp/src` directory within this repo and clone one or more repos
inside it.  The script will use this copy to clone and push during
execution. Make sure there is at least one existing release branch
(create branch 'release/0.0.0' if there are none). In production, the
github url would be used.

Create `config/list.txt` as shown below and update it with one or more
repos containing submodules.  You can choose which submodules are checked.

```bash
  $ mkdir -p config tmp/src
  # clone some repos...
  $ cp list.txt.example config/list.txt
  $ vi config/list.txt
  # Follow the directions given in the file.
```

### Run

```bash
  $ ./cut-release.sh
```

### Production

Add a crontab entry to run the script at the desired interval.  Given the
[requierments](REQUIREMENTS.txt), this is a bit tricky. Googling will
reveal some ways to run tasks every N weeks using a wrapper script.

If you have ssh access to production servers/containers, manually run
the command above as needed.
