// Usage footer - synthetic.new quota (weekly credits, 5h rate-limit window)
// in the TUI footer status slots:  [ 92.0% | 78% ]
// Refresh: session events (turn + subagent completion, 30s throttle) + 5min fallback.
// API key: OpenCode auth store (same file the nushell module reads).
import { Plugin } from "@opencode/plugin/tui";
import { createSignal } from "solid-js";

const AUTH_FILE = `${process.env.XDG_DATA_HOME ?? `${process.env.HOME}/.local/share`}/opencode/auth.json`;
const QUOTAS_URL = "https://api.synthetic.new/v2/quotas";

export default Plugin.define({
  id: "usage-footer",
  async setup(context: any) {
    const theme = context?.theme ?? {};
    const [quota, setQuota] = createSignal<{ p5: number; pw: number }>();
    const [failed, setFailed] = createSignal(false);

    async function refresh(): Promise<void> {
      try {
        const auth = await Bun.file(AUTH_FILE)
          .json()
          .catch(() => ({}));
        const key = auth?.synthetic?.key;
        if (!key) throw new Error("no api key");
        const response = await fetch(QUOTAS_URL, {
          headers: { Authorization: `Bearer ${key}` },
        });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const data = await response.json();
        const rolling = data?.rollingFiveHourLimit;
        const weekly = data?.weeklyTokenLimit;
        if (!rolling?.max || typeof weekly?.percentRemaining !== "number")
          throw new Error("bad shape");
        setQuota({
          p5: (rolling.remaining / rolling.max) * 100,
          pw: weekly.percentRemaining,
        });
        setFailed(false);
      } catch {
        setFailed(true);
      }
    }

    const render = () => {
      if (failed()) return <text fg={theme.text?.base}>[ -- ]</text>;
      const q = quota();
      return (
        <text fg={theme.text?.base}>
          {q ? `[ ${q.pw.toFixed(1)}% | ${Math.round(q.p5)}% ]` : ""}
        </text>
      );
    };

    const slots = [
      context.ui.slot({ append: "prompt.footer.status", render }),
      context.ui.slot({ append: "home.footer.status", render }),
    ];

    let lastFetch = 0;
    const throttled = () => {
      if (Date.now() - lastFetch < 30_000) return;
      lastFetch = Date.now();
      void refresh();
    };

    // documented turn-completion event
    const stopOn = context.data.on("session.execution.succeeded", throttled);
    // catch-all for everything else (incl. subagent completions) — no type
    // filtering; the throttle absorbs any event burst
    const stopListen = context.data.listen(() => throttled());
    void throttled();
    const timer = setInterval(throttled, 5 * 60_000);
    return () => {
      clearInterval(timer);
      stopOn?.();
      stopListen();
      for (const s of slots) if (typeof s === "function") s();
    };
  },
});
