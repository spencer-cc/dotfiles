// Server entrypoint for the usage-footer plugin. The TUI work happens in
// tui.tsx (loaded by the CLI); this no-op keeps the documented package pair
// (index.ts + tui.tsx) intact so both loaders resolve cleanly.
import { Plugin } from "@opencode/plugin"

export default Plugin.define({
  id: "usage-footer",
  setup() {},
})
