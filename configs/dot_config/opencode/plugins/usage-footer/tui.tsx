// Usage footer: synthetic.new weekly plan quota in the TUI footer status
// slots:  ▕███████▊░░ 78%
// Bar: filled █ cells + eighth-block boundary glyph + ░ track. Color tracks
// remaining quota: green >=60, yellow 30-60, red <30.
// Refresh: session events (30s throttle) + 5min fallback.
// API key: OpenCode auth store (same file the nushell module reads).
//
// Theme tokens are RECORDS ({base, muted}), not colors; raw records crash
// RGBA.clone. Everything must go through pick(), which unwraps .base.
import { Plugin } from "@opencode/plugin/tui";
import { createSignal } from "solid-js";

const AUTH_FILE = `${process.env.XDG_DATA_HOME ?? `${process.env.HOME}/.local/share`}/opencode/auth.json`;
const QUOTAS_URL = "https://api.synthetic.new/v2/quotas";
const BAR_CELLS = 10;
const PARTIAL = ["▏", "▎", "▍", "▌", "▋", "▊", "▉"];
// Color bands (percent remaining): red < ERROR_THRESHOLD, yellow < WARN_THRESHOLD.
const WARN_THRESHOLD = 60;
const ERROR_THRESHOLD = 30;
const FETCH_THROTTLE_MS = 30_000;
const FALLBACK_INTERVAL_MS = 5 * 60_000;

// One quota poll: auth-store key -> quotas endpoint -> validated percent.
// Throws on failure; the caller owns the error state.
async function fetchQuota(): Promise<number> {
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
  const pw = data?.planWeeklyLimit?.percentRemaining;
  if (typeof pw !== "number") throw new Error("bad shape");
  return pw;
}

// Unwraps a theme token entry to a color OpenTUI accepts (string or RGBA);
// records yield their .base. undefined is safe: fg falls back to the default.
const pick = (entry: any, ...fallbacks: any[]): any => {
  for (const v of [entry?.base ?? entry, ...fallbacks]) {
    if (typeof v === "string" || (v && typeof v === "object" && "buffer" in v))
      return v;
  }
  return undefined;
};

type ThemeColors = {
  base: any;
  track: any;
  barColor: (pct: number) => any;
};

// Footer palette: pastel .200 hue steps for the bar, dim surface gray track.
// Fallbacks degrade to feedback tokens, then base.
function resolveTheme(theme: any): ThemeColors {
  const fb = theme?.text?.feedback;
  const base = pick(theme?.text?.base);
  const barColor = (pct: number) =>
    pct < ERROR_THRESHOLD
      ? pick(theme?.hue?.red?.["200"], fb?.error, base)
      : pct < WARN_THRESHOLD
        ? pick(theme?.hue?.yellow?.["200"], fb?.warning, base)
        : pick(theme?.hue?.green?.["200"], fb?.success, base);
  return {
    base,
    barColor,
    track: pick(theme?.hue?.gray?.["700"], theme?.text?.muted),
  };
}

// Split a percent into filled/boundary/track bar strings; the boundary cell
// uses an eighth-block glyph for sub-cell precision.
function barSegments(
  pct: number,
  cells: number = BAR_CELLS,
): { filled: string; boundary: string; track: string } {
  const exact = (pct / 100) * cells;
  let full = Math.floor(exact + 1e-9);
  const eighths = Math.round((exact - full) * 8);
  if (eighths >= 8) full += 1;
  const boundary =
    eighths > 0 && eighths < 8 && full < cells ? PARTIAL[eighths - 1] : "";
  return {
    filled: "█".repeat(Math.min(full, cells)),
    boundary,
    track: "░".repeat(Math.max(cells - full - (boundary ? 1 : 0), 0)),
  };
}

const formatPercent = (pct: number): string =>
  pct.toFixed(1).replace(/\.0$/, "");

const StatusText = (props: { text: string; fg?: any }) => (
  <text fg={props.fg}>{props.text}</text>
);

// Spans need style={{fg, bg}} — bare fg/bg props are silently dropped by the
// reconciler. bg on the filled span keeps the track continuous at 91-99%.
const QuotaBar = (props: { pct: number; colors: ThemeColors }) => {
  const { filled, boundary, track } = barSegments(props.pct);
  const { barColor, track: trackColor } = props.colors;
  return (
    <>
      <span style={{ fg: barColor(props.pct), bg: trackColor }}>
        {filled + boundary}
      </span>
      <span style={{ fg: trackColor, bg: trackColor }}>{track}</span>
    </>
  );
};

const PercentLabel = (props: { pct: number; fg?: any }) => (
  <span style={{ fg: props.fg }}>{` ${formatPercent(props.pct)}% `}</span>
);

export default Plugin.define({
  id: "usage-footer",
  async setup(context: any) {
    const theme = context?.theme ?? {};
    const colors = resolveTheme(theme);
    const [quota, setQuota] = createSignal<number>();
    const [failed, setFailed] = createSignal(false);

    const refresh = async (): Promise<void> => {
      try {
        setQuota(await fetchQuota());
        setFailed(false);
      } catch {
        setFailed(true);
      }
    };

    const render = () => {
      if (failed()) return <StatusText text="[ -- ]" fg={colors.base} />;
      const pw = quota();
      if (pw === undefined) return <StatusText text=" " fg={colors.base} />;
      return (
        <text>
          <QuotaBar pct={pw} colors={colors} />
          <PercentLabel pct={pw} fg={colors.base} />
        </text>
      );
    };

    const slots = [
      context.ui.slot({ append: "prompt.footer.status", render }),
      context.ui.slot({ append: "home.footer.status", render }),
    ];

    let lastFetch = 0;
    const throttled = () => {
      if (Date.now() - lastFetch < FETCH_THROTTLE_MS) return;
      lastFetch = Date.now();
      void refresh();
    };

    // documented turn-completion event
    const stopOn = context.data.on("session.execution.succeeded", throttled);
    // catch-all for everything else (incl. subagent completions); the throttle absorbs bursts
    const stopListen = context.data.listen(() => throttled());
    void throttled();
    const timer = setInterval(throttled, FALLBACK_INTERVAL_MS);
    return () => {
      clearInterval(timer);
      stopOn?.();
      stopListen();
      for (const s of slots) if (typeof s === "function") s();
    };
  },
});
