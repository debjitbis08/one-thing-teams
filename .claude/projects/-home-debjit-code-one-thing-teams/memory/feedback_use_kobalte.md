---
name: Use Kobalte for SolidJS UI
description: Use Kobalte headless component library for all SolidJS interactive components (modals, dropdowns, etc.)
type: feedback
---

Use Kobalte (@kobalte/core) as the headless component library for SolidJS interactive elements like Dialog, Select, Popover, etc.

**Why:** Provides accessible, unstyled primitives that work well with Tailwind/Catppuccin theming. Avoids reinventing modal/dropdown behavior and keyboard handling.

**How to apply:** When building SolidJS components that need modals, selects, popovers, tooltips, etc., use Kobalte primitives instead of hand-rolling with raw divs and event handlers.
