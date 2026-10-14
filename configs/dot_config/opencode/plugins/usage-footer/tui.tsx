// Usage footer - renders synthetic.new quota in the TUI footer status slots.
// Monochrome percent pair (5h window remaining, weekly credits remaining):
//   78% · 92%
// Refresh: session events (turn + subagent completion, 30s throttle) + 5min fallback.
// API key comes from the OpenCode auth store (same file the nushell module uses).
import { Plugin } from "@opencode/plugin/tui";
import { createSignal } from "solid-js";

const AUTH_FILE = `${process.env.XDG_DATA_HOME ?? `${process.env.HOME}/.local/share`}/opencode/auth.json`;
const QUOTAS_URL = "https://api.synthetic.new/v2/quotas";
const FALLBACK_POLL_MS = 5 * 60_000;
const THROTTLE_MS = 30_000;

type Quota = { p5: number; pw: number };

async function setup(context: any) {
  const theme = context?.theme ?? {};
  const [quota, setQuota] = createSignal<Quota>();
  const [stale, setStale] = createSignal(false);

  async function apiKey(): Promise<string | undefined> {
    try {
      const auth = await Bun.file(AUTH_FILE).json();
      return auth?.synthetic?.key;
    } catch {
      return undefined;
    }
  }

  async function refresh(): Promise<void> {
    try {
      const key = await apiKey();
      if (!key) return;
      const response = await fetch(QUOTAS_URL, {
        headers: { Authorization: `Bearer ${key}` },
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const data = await response.json();
      const rolling = data?.rollingFiveHourLimit;
      const weekly = data?.weeklyTokenLimit;
      if (!rolling?.max || typeof weekly?.percentRemaining !== "number") return;
      setQuota({
        p5: (rolling.remaining / rolling.max) * 100,
        pw: weekly.percentRemaining,
      });
      setStale(false);
    } catch {
      // Keep the last known value; mark it stale so it renders dim.
      if (quota()) setStale(true);
    }
  }

  const render = () => {
    const q = quota();
    const label = q ? `[ ${q.pw.toFixed(1)}% | ${Math.round(q.p5)}% ]` : "";
    return (
      <text fg={stale() ? theme.text.muted : theme.text.base}>{label}</text>
    );
  };

  const s1 = context.ui.slot({ append: "prompt.footer.status", render });
  const s2 = context.ui.slot({ append: "home.footer.status", render });
  const unregister: unknown[] = [s1, s2];

  let lastFetch = 0;
  const throttled = (): void => {
    const now = Date.now();
    if (now - lastFetch < THROTTLE_MS) return;
    lastFetch = now;
    void refresh();
  };

  // Session events cover turn ends and subagent completions without betting
  // on individual event names; the interval is drift insurance.
  const stopListen = context.data.listen(({ details }: any) => {
    if (String(details?.type ?? "").startsWith("session.")) throttled();
  });
  void throttled();
  const timer = setInterval(throttled, FALLBACK_POLL_MS);
  return () => {
    clearInterval(timer);
    stopListen();
    for (const entry of unregister) {
      if (typeof entry === "function") (entry as () => void)();
    }
  };
}

export default Plugin.define({
  id: "usage-footer",
  async setup(context) {
    return setup(context);
  },
});
