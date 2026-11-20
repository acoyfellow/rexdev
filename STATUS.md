# rexdev status

Updated 2026-11-20. Repo: `~/cloudflare/rexdev` (local commits only, nothing pushed). Scratch Worker: `~/cloudflare/rexdev-test` (routes `/`, `/log`, `/throw`; has a `staging` env).

## Done

- `bin/rexdev`, `lib/cfg.js` (jsonc/json/toml reader), `lib/format.jq` (tail formatter), `lua/init.lua`, `install.sh`, `uninstall.sh`, `README.md`, `AGENTS.md`, `LICENSE`, `docs/how-it-works.svg`.
- No comments in any `.sh`, `.js`, `.lua`, or `.jq` file. The pre-commit hook passed on every commit.

## Verified, with the command and the result

All from `~/cloudflare/rexdev-test`, inside this Rex pane, against the real `wrangler dev` (wrangler 4.82.1).

| Command | Result |
| --- | --- |
| `rexdev up --json` | Dev pane opened. Browser pane opened at `http://localhost:8787` after the ready line. Log pane skipped with a note, since the Worker is not deployed. `curl localhost:8787/log` answered `logged`. |
| `rexdev up` again | `"reused":true`. No new panes. |
| `rexdev up --no-tail --json` in a `wrangler.toml` project (`/tmp/rd-toml`) | Worker `rexdev-toml` read from the toml. Dev server answered. `rexdev down` closed both panes. |
| `rexdev up --env staging --tail --json` | Worker name `rexdev-test-staging`. Log pane opened. It shows wrangler's "This Worker does not exist" error and stays open (`--keep-open`). |
| `rexdev status` / `--json` | Project, config, worker, wrangler version and path, dev pane and URL, preview pane, log pane. |
| `rexdev open /log`, `rexdev open /throw` | Existing preview pane navigated. `rexweb info` showed `http://localhost:8787/throw`. |
| `rexdev restart` | 2 seconds. New wrangler under the same pane. `curl` answered afterwards. |
| `rexdev down` | Closed the dev, preview, and log panes. Port 8787 closed. No pane left in `rex block ls`. |
| `rexdev deploy` with no tty and no `--yes` | `Error: rexdev deploy publishes your Worker. Add --yes to confirm.`, exit 1. |
| `rexdev deploy --dry-run --yes --json` | Pane showed `--dry-run: exiting now.` Exit 0. Output `{"block":…,"status":0,"dry_run":true}`. |
| `rexdev deploy --dry-run` in a pty, answer `n` / `y` | `n` exits 1. `y` runs the dry run and exits 0. |
| `rexdev dash --json` | Opened `https://dash.cloudflare.com/31b9…/workers/services/view/rexdev-test/production` in a rexweb pane. |
| `rexdev dash` with no `account_id` | `Error: you can reach 10 accounts. Set account_id …`, exit 1. |
| `rexdev doctor` / `--json` | All `ok`. `.ok` is `true`. |
| `rexdev --version`, `rexdev COMMAND --help` for every command, `rexdev skill` | Work. |
| `rexdev up` outside a Worker, `rexdev up --bogus`, `rexdev nope` | `Error: …` on stderr, exit 1. |
| Lua actions through `rex do` (`rexdev_up`, `rexdev_restart`, `rexdev_open`, `rexdev_deploy`, `rexdev_down`) | Each worked after install. The helper pane closes itself. `rexdev_deploy` showed the confirm prompt. I answered `n`. The `Shift-Cmd-D` binding shows in `rex keymap` as `rexdev_up`. I did not press the key itself. |
| Fresh clone: `git clone` to a temp folder, `./install.sh`, `rexdev doctor`, `./uninstall.sh` | Installed. `doctor` ran from the installer. After uninstall, `~/.config/rex/init.lua` is byte-identical to the copy I took first (`cmp`), `~/.local/bin/rexdev` and `~/.config/rex/rexdev` are gone, and no `.before-rexdev` file is left. I ran this twice. |
| `gitleaks detect --no-git --source . --redact` | `no leaks found`. |
| `guardrail publish --exit-code .` | `nothing flagged`, exit 0. |

I closed every pane I opened and removed `~/.rexdev` after testing.

## Bugs I hit and fixed

- `[ -n … ] && …` as the last line of a function exits the script under `set -e`.
- BSD `script` flushes its log every 30 seconds. `up` took 31 seconds to see the ready line. Fixed with `script -q -t 0`. Now `up` takes about 1 second.
- Killing `script` left the pane's terminal raw (staircase output after `restart`). The wrapper now restores `stty`.
- `rex split --shell=none` panes have no nvm PATH, so Rex actions could not find `wrangler`. Every normal `rexdev` run saves its PATH to `~/.rexdev/path`, and the helper pane uses it.

## Could not verify

1. **`rexdev logs` against a real deployed Worker.** Question for the orchestrator: which deployed Worker may I tail? It must have no secrets in its logs. I did not deploy anything. So far I checked only the error path (`Worker does not exist`, exit 1), and the formatter on one hand-written tail event, which is not a real test. Until then, the duration field is a guess: it uses `wallTime`, then `cpuTime`. The `--status` and `--search` flags are passed straight to `wrangler tail`.
2. **`docs/hero.png` is missing.** The README points to it. It needs a real screenshot of the three-pane layout.
3. **The log pane auto-open on a deployed Worker.** `is_deployed` looks for `Created:` in `wrangler deployments list`. I only saw the not-deployed case.
4. **The `Shift-Cmd-D` key press.** I ran the action with `rex do`, not with the key.
5. **A browser pane that takes clicks.** rexweb warned `Rex isn't showing pane …` because my Rex window may be off screen. Navigation worked, but I did not click or type in the preview.
6. **A `wrangler.json` project.** I ran jsonc and toml, not plain json. It uses the same parser as jsonc.
7. **`--remote` and project-local `node_modules/.bin/wrangler`.** The scratch Worker has no local wrangler.

NOT READY FOR REVIEW yet. Items 1 and 2 need the orchestrator. The rest of the brief is done.
