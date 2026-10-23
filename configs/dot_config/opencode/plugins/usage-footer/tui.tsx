// Usage footer - synthetic.new weekly plan quota in the TUI footer status
// slots:  ▕███████▊░░ 78%
// Bar: filled █ cells + eighth-block boundary glyph (sub-cell precision) + ░ track.
// Color tracks remaining quota: success >=60%, warning 30-60%, error <30%.
// Refresh: session events (turn + subagent completion, 30s throttle) + 5min fallback.
// API key: OpenCode auth store (same file the nushell module reads).
//
// Color values: the resolved theme exposes token RECORDS, not colors —
// theme.text.feedback.error is {base: RGBA, muted: RGBA}, theme.text.base is an
// RGBA instance. OpenTUI fg/style.fg only accepts hex/named strings or RGBA
// instances; a raw record crashes RGBA.clone (the v3 "e.length" crash). All
// colors must go through pick() below.
import { Plugin } from "@opencode/plugin/tui";
import { createSignal } from "solid-js";

const AUTH_FILE = `${process.env.XDG_DATA_HOME ?? `${process.env.HOME}/.local/share`}/opencode/auth.json`;
const QUOTAS_URL = "https://api.synthetic.new/v2/quotas";
const BAR_CELLS = 10;
const PARTIAL = ["▏", "▎", "▍", "▌", "▋", "▊", "▉"];

export default Plugin.define({
  id: "usage-footer",
  async setup(context: any) {
    const theme = context?.theme ?? {};
    const [quota, setQuota] = createSignal<number>();
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
        const pw = data?.planWeeklyLimit?.percentRemaining;
        if (typeof pw !== "number") throw new Error("bad shape");
        setQuota(pw);
        setFailed(false);
      } catch {
        setFailed(true);
      }
    }

    // Split a percent into (filled, boundary, track) bar strings; the boundary
    // cell uses an eighth-block glyph for sub-cell precision.
    function barSegments(pct: number): [string, string, string] {
      const cells = (pct / 100) * BAR_CELLS;
      let full = Math.floor(cells + 1e-9);
      const eighths = Math.round((cells - full) * 8);
      if (eighths >= 8) full += 1;
      const boundary =
        eighths > 0 && eighths < 8 && full < BAR_CELLS
          ? PARTIAL[eighths - 1]
          : "";
      return [
        "█".repeat(Math.min(full, BAR_CELLS)),
        boundary,
        "░".repeat(Math.max(BAR_CELLS - full - (boundary ? 1 : 0), 0)),
      ];
    }

    // Normalizes a resolved-theme token entry to a color OpenTUI accepts
    // (hex/named string, or RGBA instance — the type theme.text.base already
    // is). Records like {base, muted} yield their .base; never returns a
    // record. undefined is safe: fg falls back to the element default.
    const pick = (entry: any, ...fallbacks: any[]): any => {
      for (const v of [entry?.base ?? entry, ...fallbacks]) {
        if (
          typeof v === "string" ||
          (v && typeof v === "object" && "buffer" in v)
        )
          return v;
      }
      return undefined;
    };
    const fb = theme?.text?.feedback;
    const baseFg = theme?.text?.base;
    // Pastel catppuccin look: lighter hue-ramp steps (.200) for the bar, dim
    // surface gray for the track. Fallbacks degrade to feedback tokens, then base.
    // Bands: green >=60, yellow 30-60, red <30 (percent remaining).
    const barColor = (pct: number) =>
      pct < 30
        ? pick(theme?.hue?.red?.["200"], fb?.error, baseFg)
        : pct < 60
          ? pick(theme?.hue?.yellow?.["200"], fb?.warning, baseFg)
          : pick(theme?.hue?.green?.["200"], fb?.success, baseFg);
    const trackColor = pick(theme?.hue?.gray?.["700"], theme?.text?.muted);

    const render = () => {
      if (failed()) return <text fg={pick(baseFg)}>[ -- ]</text>;
      const pw = quota();
      if (pw === undefined) return <text fg={pick(baseFg)}> </text>;
      // Two-tone bar via spans: bare fg/bg props on spans are silently dropped
      // by the reconciler — only style={{fg, bg}} reaches TextNodeRenderable.
      // bg on the filled+boundary span keeps the track strip continuous at
      // 91-99% (boundary cell's uncovered fraction shows the gray).
      const [filled, boundary, track] = barSegments(pw);
      return (
        <text>
          <span style={{ fg: barColor(pw), bg: trackColor }}>
            {filled + boundary}
          </span>
          <span style={{ fg: trackColor, bg: trackColor }}>{track}</span>
          <span style={{ fg: pick(baseFg) }}>
            {` ${pw.toFixed(1).replace(/\.0$/, "")}% `}
          </span>
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
