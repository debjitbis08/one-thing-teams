# OneThing for Teams

**OneThing for Teams** is a collaborative planning tool that helps teams stay aligned on their most important work by practicing the principle: **do one thing at a time, finish it, and only then move on.**

It is designed for product-focused teams who want to maximize impact through clarity, prioritization, and deliberate scope control.

---

## 🚀 Getting Started

```bash
pnpm install    # Install dependencies
pnpm dev        # Start the development server
pnpm build      # Build for production
```

---

## 📂 Project Highlights

* **Domain-driven design**
  Contexts are organized under `src/contexts` (e.g., foundation, common, product management).

* **Shared utilities**
  Reusable helpers for logging, errors, and configuration in `src/utilities` and `src/config`.

* **API routes**
  Handlers for team-facing features in `src/pages/api`.

---

## 📖 Core Philosophy

* **Initiative Prioritization** → Work is ranked by *user value, urgency, risk reduction,* and *effort*.
* **Initiative Pruning** → Scope is cut intentionally when time runs out to still deliver value.
* **Team Focus** → Each team owns **one initiative** at a time, commits fully, and finishes cleanly.

Idleness is acceptable. Multitasking is not.

---

## 🔑 Key Concepts

* **Initiatives** – Discrete chunks of work that deliver visible user impact within one cycle.
* **Cycles** – Fixed timeboxes (default: six weeks) that enforce focus and natural reassessment.
* **Done = In Use** – An initiative is *only done* when real users are actually using it.
* **Emergencies** – The only valid interruption; everything else waits.

---

## 📘 Learn More

For the full operating guide, see the [OneThing for Teams Playbook](docs/OneThing_for_Teams_Playbook.pdf)
