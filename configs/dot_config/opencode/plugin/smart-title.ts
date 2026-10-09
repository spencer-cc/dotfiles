// Smart Title - V2 port of @tarquinen/opencode-smart-title 0.1.7 (V1-only upstream).
// Regenerates session titles from conversation context every `updateThreshold`
// idle events. Options stay in smart-title.jsonc next to opencode.jsonc:
//   enabled, debug, model ("provider/id"), updateThreshold
import { Plugin } from "@opencode/plugin"
import { appendFileSync, mkdirSync } from "node:fs"

type ModelRef = { providerID: string; id: string }
type AnyMessage = { type: string; text?: string }

interface SmartTitleConfig {
  enabled?: boolean
  debug?: boolean
  model?: string
  updateThreshold?: number
}

const CONFIG_DIR = `${process.env.XDG_CONFIG_HOME ?? `${process.env.HOME}/.config`}/opencode`
const LOG_DIR = `${CONFIG_DIR}/logs/smart-title`

let debugOn = false

function debug(msg: string): void {
  if (!debugOn) return
  try {
    mkdirSync(LOG_DIR, { recursive: true })
    appendFileSync(
      `${LOG_DIR}/${new Date().toISOString().slice(0, 10)}.log`,
      `${new Date().toISOString()} ${msg}\n`,
    )
  } catch {
    // Logging must never break titling.
  }
}

// JSONC reader: strips comments and trailing commas; missing file means defaults.
async function readConfig(): Promise<SmartTitleConfig> {
  try {
    const text = await Bun.file(`${CONFIG_DIR}/smart-title.jsonc`).text()
    const stripped = text
      .replace(/\/\*[\s\S]*?\*\//g, "")
      .split("\n")
      .filter((line) => !line.trimStart().startsWith("//"))
      .join("\n")
      .replace(/,(\s*[}\]])/g, "$1")
    return JSON.parse(stripped) as SmartTitleConfig
  } catch {
    return {}
  }
}

// "provider/model" -> model ref; the id may itself contain "/" (e.g. hf:org/name).
function parseModel(spec: string | undefined): ModelRef | undefined {
  if (!spec) return undefined
  const cut = spec.indexOf("/")
  if (cut <= 0 || cut === spec.length - 1) return undefined
  return { providerID: spec.slice(0, cut), id: spec.slice(cut + 1) }
}

function excerpt(messages: readonly AnyMessage[]): string {
  const parts: string[] = []
  for (const message of messages) {
    if (message.type !== "user" || !message.text) continue
    parts.push(message.text)
    if (parts.length >= 3) break
  }
  const joined = parts.join("\n---\n").trim()
  return joined.length > 1600 ? `${joined.slice(0, 1600)}...` : joined
}

function cleanTitle(text: string): string | undefined {
  const first = text.trim().split("\n")[0] ?? ""
  const title = first.replace(/^["'`]+|["'`.]+$/g, "").trim()
  if (!title) return undefined
  return title.length > 60 ? `${title.slice(0, 57)}...` : title
}

export default Plugin.define({
  id: "smart-title",
  async setup(ctx) {
    const idleCount = new Map<string, number>()

    async function retitle(sessionID: string, cfg: SmartTitleConfig): Promise<void> {
      const messages: readonly AnyMessage[] = await ctx.session.context({ sessionID })
      const context = excerpt(messages)
      if (!context) return

      const prompt = [
        "Pick a concise title (3-6 words) for this coding session.",
        "Reply with the title only: no quotes, no trailing punctuation, no explanation.",
        "",
        context,
      ].join("\n")

      // Configured model first, session default as fallback.
      const candidates: ModelRef[] = []
      const configured = parseModel(cfg.model)
      if (configured) candidates.push(configured)
      const fallback = await ctx.model.default.get()
      if (fallback) candidates.push({ providerID: fallback.providerID, id: fallback.modelID })

      for (const model of candidates) {
        try {
          const generated = await ctx.generate.text({ model, prompt })
          const title = cleanTitle(generated.text)
          if (!title) continue
          await ctx.session.update({ sessionID, title })
          debug(`retitled ${sessionID}: ${title}`)
          return
        } catch (error) {
          debug(`generate failed (${model.providerID}/${model.id}): ${error}`)
        }
      }
    }

    const controller = new AbortController()
    void (async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        if (event.type !== "session.idle") continue
        try {
          const cfg = await readConfig()
          debugOn = cfg.debug === true
          if (cfg.enabled === false) continue
          const sessionID = event.data.sessionID
          const threshold = Math.max(1, Math.floor(cfg.updateThreshold ?? 1))
          const seen = (idleCount.get(sessionID) ?? 0) + 1
          idleCount.set(sessionID, seen)
          if (seen % threshold !== 0) continue
          await retitle(sessionID, cfg)
        } catch (error) {
          debug(`retitle failed: ${error}`)
        }
      }
    })()

    // Abort the subscription when the plugin unloads.
    return () => controller.abort()
  },
})
