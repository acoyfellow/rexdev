const fs = require("fs");

const file = process.argv[2];
const env = process.argv[3] || "";
const text = fs.readFileSync(file, "utf8");

function stripJsonc(src) {
  let out = "";
  let i = 0;
  let inString = false;
  while (i < src.length) {
    const c = src[i];
    const n = src[i + 1];
    if (inString) {
      out += c;
      if (c === "\\") {
        out += n;
        i += 2;
        continue;
      }
      if (c === '"') inString = false;
      i += 1;
      continue;
    }
    if (c === '"') {
      inString = true;
      out += c;
      i += 1;
    } else if (c === "/" && n === "/") {
      while (i < src.length && src[i] !== "\n") i += 1;
    } else if (c === "/" && n === "*") {
      i += 2;
      while (i < src.length && !(src[i] === "*" && src[i + 1] === "/")) i += 1;
      i += 2;
    } else {
      out += c;
      i += 1;
    }
  }
  return out.replace(/,(\s*[}\]])/g, "$1");
}

function parseToml(src) {
  const top = {};
  const envs = {};
  let section = "";
  for (const raw of src.split("\n")) {
    const line = raw.trim();
    if (line === "" || line[0] === "#") continue;
    const head = line.match(/^\[+\s*([^\]]+?)\s*\]+$/);
    if (head) {
      section = head[1];
      continue;
    }
    const kv = line.match(/^([A-Za-z_]+)\s*=\s*"([^"]*)"/);
    if (!kv) continue;
    if (section === "") top[kv[1]] = kv[2];
    const e = section.match(/^env\.([^.]+)$/);
    if (e) {
      envs[e[1]] = envs[e[1]] || {};
      envs[e[1]][kv[1]] = kv[2];
    }
  }
  return { ...top, env: envs };
}

let cfg;
try {
  cfg = file.endsWith(".toml") ? parseToml(text) : JSON.parse(stripJsonc(text));
} catch (e) {
  process.stderr.write("cannot parse " + file + ": " + e.message + "\n");
  process.exit(1);
}

const block = env && cfg.env && cfg.env[env] ? cfg.env[env] : {};
let name = cfg.name || "";
if (env) name = block.name || (name ? name + "-" + env : "");

process.stdout.write(
  JSON.stringify({
    name,
    account_id: block.account_id || cfg.account_id || "",
    main: block.main || cfg.main || "",
    env_defined: env ? Boolean(cfg.env && cfg.env[env]) : true,
  }) + "\n"
);
