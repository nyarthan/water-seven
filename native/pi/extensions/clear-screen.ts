import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Container, Key } from "@earendil-works/pi-tui";

export default function clearScreen(pi: ExtensionAPI) {
  pi.registerShortcut(Key.ctrl("l"), {
    description: "Clear the visible screen without changing the session",
    handler: async (ctx) => {
      if (ctx.mode !== "tui") return;

      if (!ctx.isIdle()) {
        ctx.ui.notify("The screen can only be cleared while pi is idle.", "warning");
        return;
      }

      await ctx.ui.custom<void>((tui, _theme, _keybindings, done) => {
        // Pi's first three root containers hold the header, loaded-resource
        // summary, and chat transcript. Clearing them only changes the current
        // TUI; the SessionManager and its entries remain untouched.
        for (const component of tui.children.slice(0, 3)) {
          if (component instanceof Container) component.clear();
        }

        done();
        tui.requestRender(true);

        // done() closes this immediately, so this component is never mounted.
        return { render: () => [], invalidate: () => {} };
      });
    },
  });
}
