Integrating sst/opencode into Heimdall
Below are three approaches to vendor and rebrand the opencode CLI library in Heimdall. Each covers setup steps, folder structure, update strategy, and pros/cons.
1. Git Subtree Vendor Approach
Add as subtree: In your Heimdall repo, add opencode under vendor/opencode using git subtree. For example:
# Add an “opencode” remote and pull in its dev (or main) branch
git remote add opencode https://github.com/sst/opencode.git
git subtree add --prefix=vendor/opencode opencode dev --squash
This creates a new folder vendor/opencode containing opencode’s source (squashed into one commit if --squash is used). Heimdall can then import or execute code from vendor/opencode (for example, referencing its modules via relative paths). The folder structure becomes:
Heimdall/
├─ vendor/
│   └─ opencode/   # subtree copy of sst/opencode
├─ src/            # Heimdall code
└─ package.json    # Heimdall config
Update subtree: To pull upstream changes later, use git subtree pull with the same prefix:
git fetch opencode dev
git subtree pull --prefix=vendor/opencode opencode dev --squash
This merges new commits from opencode into vendor/opencode. It generates a merge commit under the subtree prefix
medium.com
. (Using --squash is common to keep a single commit of all upstream changes.) Always commit the result in Heimdall’s repo. Usage in Heimdall: Heimdall code can invoke opencode by importing from the vendor/opencode path. For example, if opencode exports a function, you might do:
import { runAgent } from '../vendor/opencode/src/agent';
Adjust tsconfig.json or module paths as needed so Heimdall finds those files. Pros: Subtrees are self-contained and don’t require extra git initialization. After cloning Heimdall, the entire opencode code is already present (no extra commands for users)
medium.com
. Workflow is simpler: you use normal git pull, subtree pull, etc., without managing .gitmodules or special clones
medium.com
. Merge conflicts are usually straightforward to resolve in one repo
medium.com
. Cons: The repo size grows because opencode history is merged in. Pulling new updates requires git subtree commands, which can be tricky the first time. Contributing changes from Heimdall back upstream is more complex (you’d use git subtree push)
medium.com
medium.com
. Also, rebasing after a subtree pull is problematic (git may lose the prefix)
medium.com
. In practice, keep subtree pulls as separate merges and consider squashing to avoid repeating commits
medium.com
. Warnings: Don’t modify the upstream code in place if you want to keep tracking. If you do need patches, apply them as separate commits in the subtree directory and be prepared to merge them upstream carefully. Always double-check that merges used the correct --prefix.
2. Git Submodule Vendor Approach
Add as submodule: In Heimdall, add opencode as a submodule at vendor/opencode:
git submodule add https://github.com/sst/opencode.git vendor/opencode
This creates vendor/opencode as a separate git repo and a .gitmodules file like:
[submodule "vendor/opencode"]
    path = vendor/opencode
    url = https://github.com/sst/opencode.git
git-scm.com
git-scm.com
. Commit the updated .gitmodules. Cloning Heimdall with submodules: For new clones, either use the --recurse-submodules flag:
git clone --recurse-submodules https://github.com/yourorg/heimdall.git
or after a normal clone run:
git submodule update --init --recursive
Without this, vendor/opencode will exist as an empty directory (with a special gitlink)
git-scm.com
. For example, a fresh clone shows vendor/opencode/ present but empty until git submodule init and git submodule update are run
git-scm.com
git-scm.com
. Updating the submodule: Inside Heimdall, update opencode by moving into vendor/opencode and pulling changes:
cd vendor/opencode
git fetch origin dev   # or the appropriate branch
git merge origin/dev   # or checkout, or use git pull
Then return and commit the new submodule pointer:
cd ../..
git add vendor/opencode
git commit -m "Update opencode submodule to latest"
Alternatively, use the umbrella command:
git submodule update --remote vendor/opencode
git add vendor/opencode
git commit -m "Update opencode submodule"
This fetches and checks out the latest commit in the submodule (similar to git pull)
git-scm.com
. Usage in Heimdall: The code in vendor/opencode lives in a normal folder but is a separate repo. You can import its files the same way as with a subtree. Ensure your build or script path includes that directory. Pros: Submodules cleanly separate the histories. You can update opencode by exactly pinning to a commit. Changes inside vendor/opencode stay in its own Git repo, so you can easily work on it or push fixes upstream without polluting Heimdall’s history. Cons: Submodules require extra steps. Every user must initialize and update the submodule to get the files (otherwise the directory stays empty)
git-scm.com
git-scm.com
. Submodule refs live in .gitmodules, which is new metadata that developers must manage
git-scm.com
. Remember to commit the submodule pointer (the special "subproject commit") after any update
git-scm.com
. Submodules can be confusing: forgetting git submodule update or not rebasing properly can leave teammates with stale code
git-scm.com
. Also, normal git pull in the superproject won’t update submodules by default – you must run git submodule update --remote or re-run git submodule init/update each time upstream changes. Baggio notes submodules add workflow complexity (new commands and metadata) that subtrees avoid
medium.com
git-scm.com
. Warnings: If you rename or move vendor/opencode, the path in .gitmodules breaks – use git mv on the submodule path or update .gitmodules carefully. After merging new upstream changes, do a git submodule update to sync. Always push both the .gitmodules and updated commit to your Heimdall repo so others get the changes.
3. Fork + Rebranding Branch Approach
Fork and clone: Create a fork of sst/opencode (e.g. yourorg/opencode) on GitHub. Clone your fork into Heimdall (or rename it to heimdall in your organization). In this fork, keep two lines of development: one tracks the upstream, and one holds your rebranding. For example, in Git:
git remote add upstream https://github.com/sst/opencode.git
git fetch upstream
# Create an "upstream-dev" branch tracking original dev (or main)
git checkout -b upstream-dev upstream/dev
Now create a branch for Heimdall’s code (it could be main or heimdall):
git checkout -b heimdall
In heimdall, do the rebranding (see below). Branch structure:
upstream-dev – mirrors sst/opencode’s dev branch (keep this in sync with upstream).
heimdall (or main) – your rebranded code, with all name changes.
You might keep your fork’s default branch as heimdall. The key is: do not make heavy changes on the upstream-dev branch – it should stay in sync with original. All modifications for Heimdall go on the heimdall branch. Merging upstream updates: When sst/opencode publishes updates, update your fork:
git checkout upstream-dev
git pull upstream dev        # or upstream/main as appropriate
This brings upstream-dev up to date with the original. Then merge those changes into your rebrand branch:
git checkout heimdall
git merge upstream-dev
If there are conflicts, resolve them (especially around renamed files, see next). This keeps Heimdall current with new upstream features while preserving rebranding. The GitHub CLI also offers gh repo sync, but the manual fetch/merge approach works universally
docs.github.com
docs.github.com
. Rebranding edits: On the heimdall branch, perform your renames and changes. Typical steps:
Rename directories/files via git mv so history is preserved (e.g. git mv opencode Heimdall).
Update imports and code references (e.g. replace occurrences of "opencode" with "heimdall" in code and docs). You can use search-and-replace tools or codemods (e.g. grep + sed, or a JS codemod). Commit in logical batches: first rename files, then update code, then adjust documentation.
Change package names and CLI commands (in package.json, README, command scripts).
For example:
git mv src/cli.ts src/heimdall-cli.ts
grep -rl "opencode" -e 'opencode' | xargs sed -i 's/opencode/heimdall/g'
git add .
git commit -m "Rebrand opencode to Heimdall"
Run tests or try the CLI to ensure nothing broke. Tips for heavy renames: If you rename many identifiers, expect merge conflicts when pulling upstream. One strategy is to first merge upstream before doing large renames, so that you only have to resolve conflicts once. Alternatively, merge upstream after renaming but be prepared to manually resolve (Git’s rename detection helps, but some conflicts may occur). Always test each merge. Using git mv for files tells Git about renames, reducing conflicts. For code, careful regex or codemod usage is best to avoid missing any reference. Pros: You have full control. Heimdall’s code can diverge arbitrarily. No subtree or submodule complexity: it’s just one repository where you can refactor freely. You can also push fixes upstream by making PRs from your fork. Cons: Manual maintenance overhead. Every upstream update requires a merge into your rebrand branch and conflict resolution. Large renames make merges harder. Your fork’s history diverges, so extra care is needed to avoid deviating too much or missing security fixes. If upstream deletes or radically restructures code, merging could be painful. Warnings: Keep the upstream-dev branch unchanged by your changes – only merge upstream-dev into heimdall. Avoid making your first commit a massive rename of everything, because merging in later commits will be a nightmare. Instead, rebrand iteratively (e.g. rename core identifiers first, test, then rename CLI, etc.). Always keep a copy or reset of the upstream branch to fall back on. Remember to push both branches to your remote fork so CI or collaborators can see them. Synchronizing forks: In summary, the pattern is:
# On Heimdall rebrand branch
git checkout upstream-dev
git pull upstream dev        # sync upstream changes
git checkout heimdall
git merge upstream-dev       # merge into rebranded branch
This standard flow (also documented by GitHub) ensures your fork stays up-to-date
docs.github.com
docs.github.com
. Overall Advice: Choose subtree if you want an easy, no-extra-setup approach and don’t mind a monolithic repo. Choose submodule if you want a clear separation and are okay with the init/update overhead. Choose a fork+rebrand if you plan to heavily customize the code and want full independence (at the cost of tedious renaming/merging work). In each case, include clear steps (like above), carefully document new commands for developers (especially for submodules), and periodically merge/pull from upstream to stay current.