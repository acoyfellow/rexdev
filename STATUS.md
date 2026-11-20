# rexdev status

Updated 2026-11-20, after the orchestrator's answers. Repo: `~/cloudflare/rexdev` (local commits only, nothing pushed). Scratch Worker: `~/cloudflare/rexdev-test` (routes `/`, `/log`, `/throw`; has a `staging` env).

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
| `rexdev logs` from `~/cloudflare/rexbox/cloud`, with real traffic from `cloudflared access curl …/_rexbox/boxes` and `…/_rexbox/nope` | Two lines of output per request: `GET /_rexbox/boxes 200 50ms`, `GET /_rexbox/nope 404 1ms`, plus a Durable Object line (`do Index ok 11ms`). Colors checked on the same real events: 200 green, 404 yellow. |
| Duration field | Real events carry `wallTime` and `cpuTime`. The formatter uses `wallTime`. Confirmed (400ms wall, 4ms CPU on the first request). |
| Request headers | Real events include headers (an auth header among them). The formatter prints none: grep of its output for `token` and `cf-access` finds 0 matches. |
| `rexdev logs --status error` | Shows nothing for these traffic events. Both have outcome `ok`, and wrangler filters on outcome, not HTTP status, so a 404 is not an error. I could not make this Worker throw, so a positive match is untested. Help text now says so. |
| `rexdev logs --search nope` and `--search zzzznomatch` | Both show nothing. rexbox writes no `console.log` lines, so `--search` has nothing to match. A positive match is untested. |
| Deployed-Worker check, by itself (`wrangler deployments list --name rexbox`) | 20 `Created:` lines, so `is_deployed` is true. For `rexdev-test` the command fails with code 10007, so it is false. I did not run `up` against the rexbox config, since it has no way to skip `wrangler dev`. |
| `rexdev up` in a plain `wrangler.json` project (`/tmp/rd-json`, with a trailing comma) | Worker `rexdev-json` read. Dev server answered. `down` closed the pane. |
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
- `wrangler tail --format json` prints each event as indented, multi-line JSON. The first formatter read one line at a time and would have shown nothing. It now reads the JSON stream. wrangler writes its errors to stderr, so they cannot break it.
- `is_deployed` now runs wrangler from the project folder.
- Durable Object events showed the Worker name. They now show `do  ClassName`.

## Not verified

1. A positive match for `--status error` (needs a Worker that throws, and a deployed one) and for `--search` (needs a Worker that logs). Both flags go straight to `wrangler tail`, and I saw them filter events out.
2. `docs/hero.png` is missing on purpose. The user takes the screenshot at the end.
3. The `Shift-Cmd-D` key press. I ran each action with `rex do`, not with the key.
4. A browser pane that takes clicks. rexweb warned `Rex isn't showing pane …` because my Rex window may be off screen. Navigation worked. I did not click or type in the preview.
5. The auto-open log pane on a deployed Worker. I tested its two parts, `is_deployed` and the `--tail` pane, but not `up` end to end against a deployed Worker.
6. `--remote`, and a project-local `node_modules/.bin/wrangler`.
7. `rexdev dash` was checked up to the pane and URL. I did not check that the dashboard page loads, since rexweb has no Cloudflare sign-in.

READY FOR REVIEW
