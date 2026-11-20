# rexdev for coding agents

rexdev lays out the Cloudflare Workers dev loop in a Rex window: a pane for
`wrangler dev`, a browser pane for its URL, and a log pane for the deployed
Worker. Print this guide with `rexdev skill`.

## Check it

```sh
rexdev doctor      # one line per check; exits 1 if any check fails
```

## Use it

Run these in a Worker project, from a Rex pane.

```sh
rexdev up --json                  # dev pane, preview pane, and log pane if deployed
url=$(rexdev up --no-open)        # dev pane only; prints the dev URL
rexdev status --json              # project, panes, dev URL, wrangler version
rexdev open /health --json        # preview at a path; prints {block, url}
rexdev restart                    # restart wrangler dev; prints the dev URL
rexdev logs --status error        # readable tail of the deployed Worker
rexdev deploy --dry-run --yes     # wrangler deploy --dry-run in a pane
rexdev dash --json                # the Worker's dashboard page in a pane
rexdev down                       # close the panes and stop wrangler dev
```

- `rexdev up` reuses the panes that are open. Run it again freely.
- Read the dev server's output with `rex capture -b ID --trim`. `rexdev status --json` gives the pane ID in `.dev.pane`.
- Drive the preview with `rexweb snapshot -b ID`, using `.web.pane`. A rexweb pane takes clicks and typing only while it is on screen.
- Pass wrangler flags after `--`: `rexdev up -- --port 9000`.
- `--config FILE` and `--env ENV` work on every command that reads the config.
- `rexdev logs` needs a deployed Worker. It runs in the current terminal until you press Ctrl-C.
- `rexdev deploy` publishes the Worker. Without `--dry-run`, it is a real deploy. Never run it unless the person asked.
- `rexdev deploy` needs `--yes` when no one is at the terminal.
- `--json` works on `up`, `open`, `deploy`, `dash`, `status`, and `doctor`.
- Errors go to stderr as `Error: ...`, with exit status 1.

## Rules

- Run `rexdev down` when you finish, so no dev server stays behind.
- Close only the panes that rexdev opened. `rexdev down` does this.
- Don't read `.dev.vars`. Don't print secrets from the dev or log panes.

## When something breaks

1. Run `rexdev doctor` and fix each `FAIL` line.
2. Run `rexdev status` to see which panes exist.
3. Read the dev pane: `rex capture -b ID --trim`.
4. Run `rexdev down`, then `rexdev up`.
5. Reinstall: run `./install.sh` in the rexdev repo.
