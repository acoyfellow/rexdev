local M = {}

local SHELL = "com.superlogical.terminal.shell"
local BIN = "@BIN@"
if BIN:sub(1, 1) == "@" then BIN = os.getenv("HOME") .. "/.local/bin/rexdev" end

local defaults = {
  key = "shift+cmd+d",
  restart_key = false,
  open_key = false,
  deploy_key = false,
}

local function helper(verb, anchor, arg)
  local command = { BIN, "_act", verb, anchor, arg or "" }
  return rex.layout.block{ flavor = SHELL, label = "rexdev " .. verb, options = { command = command } }
end

local function define(name, title, description, verb, keywords, args)
  rex.action{
    name = name,
    title = title,
    description = description,
    category = "Workers",
    keywords = keywords,
    args = args,
    run = function(ctx, a)
      local arg = a and (a.path or "") or ""
      local split, err = rex.session.new_split{
        anchor_id = ctx.block_id,
        direction = "vertical",
        side = "after",
        ratio = verb == "deploy" and 0.6 or 0.9,
        focus = verb == "deploy",
        layout = helper(verb, ctx.block_id, arg),
      }
      if err ~= nil then error(err, 0) end
      return split
    end,
  }
end

function M.setup(opts)
  opts = opts or {}
  for k, v in pairs(defaults) do
    if opts[k] == nil then opts[k] = v end
  end

  define("rexdev_up", "Workers: Start Dev Loop",
    "Open wrangler dev, a browser preview, and a log view beside this pane.",
    "up", "workers wrangler dev cloudflare preview loop")
  define("rexdev_restart", "Workers: Restart Dev Server",
    "Restart wrangler dev and reload the preview.",
    "restart", "workers wrangler dev restart reload")
  define("rexdev_open", "Workers: Open Preview",
    "Open or refocus the dev server preview. Give a path to open it there.",
    "open", "workers wrangler preview browser open", { path = "string?" })
  define("rexdev_deploy", "Workers: Deploy",
    "Run wrangler deploy in a pane, after you confirm.",
    "deploy", "workers wrangler deploy publish")
  define("rexdev_down", "Workers: Stop Dev Loop",
    "Close the rexdev panes and stop wrangler dev.",
    "down", "workers wrangler dev stop close")

  if opts.key then rex.bind(opts.key, "rexdev_up") end
  if opts.restart_key then rex.bind(opts.restart_key, "rexdev_restart") end
  if opts.open_key then rex.bind(opts.open_key, "rexdev_open") end
  if opts.deploy_key then rex.bind(opts.deploy_key, "rexdev_deploy") end
end

return M
