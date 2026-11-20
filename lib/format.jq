def paint($code; $s): if $color == 1 then "\u001b[\($code)m\($s)\u001b[0m" else $s end;
def pad($n): tostring | . + (" " * $n) | .[0:$n];
def hms: (. / 1000 | floor | localtime | strftime("%H:%M:%S"));
def words: map(if type == "string" then . else tojson end) | join(" ");

select(type == "object") | . as $e
| ($e.event // {}) as $ev
| ($ev.request // null) as $req
| ($ev.response.status // null) as $st
| ($e.wallTime // $e.cpuTime // null) as $ms
| ($st // 0) as $code
| (if $e.outcome == "exception" or $code >= 500 then "31"
   elif $code >= 400 then "33"
   elif $e.outcome == "ok" or $code > 0 then "32"
   else "35" end) as $tone
| (
    paint("2"; ($e.eventTimestamp // 0 | hms)) + "  "
    + (if $req != null then
        paint("1"; ($req.method | pad(6))) + " "
        + ($req.url | sub("^https?://[^/]+"; "") | if . == "" then "/" else . end)
        + "  " + paint($tone; (if $st != null then ($st | tostring) else ($e.outcome // "?") end))
        + (if $ms != null then paint("2"; "  \($ms)ms") else "" end)
      else
        paint("1"; (if $e.durableObjectId != null then "do     " + ($e.entrypoint // $e.scriptName // "")
                    elif $ev.cron != null then "cron   " + ($ev.cron | tostring)
                    elif $ev.queue != null then "queue  " + ($ev.queue | tostring)
                    elif $ev.mailFrom != null then "email  " + ($ev.mailFrom | tostring)
                    else ($e.scriptName // "event") end))
        + "  " + paint($tone; ($e.outcome // "?"))
        + (if $ms != null then paint("2"; "  \($ms)ms") else "" end)
      end)
  ),
  ($e.logs[]? | "  " + paint("2"; (.level // "log" | pad(5))) + " " + (.message | if type == "array" then words else tostring end)),
  ($e.exceptions[]? | "  " + paint("31"; "✘ \(.name // "Error"): \(.message // "")"))
