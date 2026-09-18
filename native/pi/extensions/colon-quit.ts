import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function colonQuit(pi: ExtensionAPI) {
  pi.on("input", (event, ctx) => {
    if (event.text.trim() !== ":q") return;

    ctx.shutdown();
    return { action: "handled" };
  });
}
