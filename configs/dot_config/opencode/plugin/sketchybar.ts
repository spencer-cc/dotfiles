// Trigger a sketchybar event when a session goes idle (V2 plugin API).
import { $ } from "bun"
import { Plugin } from "@opencode/plugin"

export default Plugin.define({
  id: "sketchybar",
  setup(ctx) {
    // Only run when sketchybar is installed (macOS-specific)
    if (!Bun.which("sketchybar")) return
    const controller = new AbortController()
    void (async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        if (event.type !== "session.idle") continue
        try {
          // nothrow: sketchybar might not be running - stay silent
          await $`sketchybar --trigger opencode-completion`.quiet().nothrow()
        } catch {
          // ignore
        }
      }
    })()
    // Abort the subscription when the plugin unloads
    return () => controller.abort()
  },
})
