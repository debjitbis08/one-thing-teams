import { createSignal, Show, For, type Component } from "solid-js";
import { Dialog } from "@kobalte/core/dialog";
import { FiPlus, FiX, FiTarget, FiBarChart2, FiCheckCircle } from "solid-icons/fi";
import { TbOutlineRocket } from "solid-icons/tb";

// --- Types ---

type Initiative = {
  initiativeId: string;
  slug: string;
  title: string;
  description: string | null;
  timeBudget: number;
  chatRoomLink: string | null;
  progressStatus: string;
  lifecycleStatus: string;
  score: {
    scoreType: string;
    isCore: boolean;
  } | null;
  createdAt: string;
};

type Product = {
  productId: string;
  name: string;
};

type Props = {
  initiatives: Initiative[];
  currentProduct: Product;
};

// --- Status colors ---

const statusColors: Record<string, string> = {
  thinking: "bg-ctp-blue/10 text-ctp-blue",
  trying: "bg-ctp-sapphire/10 text-ctp-sapphire",
  building: "bg-ctp-teal/10 text-ctp-teal",
  finishing: "bg-ctp-green/10 text-ctp-green",
  deploying: "bg-ctp-peach/10 text-ctp-peach",
  distributing: "bg-ctp-mauve/10 text-ctp-mauve",
  stuck: "bg-ctp-red/10 text-ctp-red",
};

const lifecycleColors: Record<string, string> = {
  waiting: "bg-ctp-overlay0/10 text-ctp-overlay0",
  active: "bg-ctp-green/10 text-ctp-green",
  done: "bg-ctp-blue/10 text-ctp-blue",
  abandoned: "bg-ctp-surface1 text-ctp-subtext0",
};

// --- Input field helper ---

const inputClass = "w-full px-3 py-2 rounded-lg border border-ctp-surface1 bg-ctp-surface0 text-ctp-text placeholder-ctp-overlay0 focus:outline-none focus:ring-2 focus:ring-ctp-mauve focus:border-transparent text-sm";

// --- Create Dialog ---

const CreateInitiativeDialog: Component<{
  open: boolean;
  onOpenChange: (open: boolean) => void;
  productId: string;
}> = (props) => {
  const [title, setTitle] = createSignal("");
  const [description, setDescription] = createSignal("");
  const [timeBudget, setTimeBudget] = createSignal("");
  const [chatRoomLink, setChatRoomLink] = createSignal("");
  const [loading, setLoading] = createSignal(false);
  const [error, setError] = createSignal("");

  const reset = () => {
    setTitle("");
    setDescription("");
    setTimeBudget("");
    setChatRoomLink("");
    setError("");
  };

  const create = async () => {
    setLoading(true);
    setError("");
    try {
      const body: Record<string, unknown> = {
        productId: props.productId,
        title: title(),
      };
      if (description().trim()) body.description = description();
      if (timeBudget()) body.timeBudget = parseFloat(timeBudget());
      if (chatRoomLink().trim()) body.chatRoomLink = chatRoomLink();

      const res = await fetch("/api/initiatives", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      const data = await res.json();
      if (res.ok) {
        reset();
        props.onOpenChange(false);
        window.location.reload();
      } else {
        setError(data.error || "Failed to create initiative");
      }
    } catch {
      setError("Network error");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog
      open={props.open}
      onOpenChange={(open) => {
        if (!open) reset();
        props.onOpenChange(open);
      }}
    >
      <Dialog.Portal>
        <Dialog.Overlay class="fixed inset-0 z-50 bg-ctp-crust/60 backdrop-blur-sm data-[expanded]:animate-in data-[expanded]:fade-in-0 data-[closed]:animate-out data-[closed]:fade-out-0" />
        <div class="fixed inset-0 z-50 flex items-center justify-center">
          <Dialog.Content class="w-full max-w-lg mx-4 bg-ctp-mantle border border-ctp-surface0 rounded-xl shadow-2xl data-[expanded]:animate-in data-[expanded]:fade-in-0 data-[expanded]:zoom-in-95 data-[closed]:animate-out data-[closed]:fade-out-0 data-[closed]:zoom-out-95">
            {/* Header */}
            <div class="flex items-center justify-between px-6 py-4 border-b border-ctp-surface0">
              <Dialog.Title class="text-base font-semibold text-ctp-text">
                New initiative
              </Dialog.Title>
              <Dialog.CloseButton class="text-ctp-overlay1 hover:text-ctp-text transition-colors">
                <FiX size={20} />
              </Dialog.CloseButton>
            </div>

            {/* Body */}
            <div class="px-6 py-4 space-y-4">
              <Dialog.Description class="sr-only">
                Create a new initiative for your product
              </Dialog.Description>

              <Show when={error()}>
                <div class="p-3 rounded-lg bg-ctp-red/10 text-ctp-red text-sm">{error()}</div>
              </Show>

              <div>
                <label for="init-title" class="block text-sm font-medium text-ctp-subtext1 mb-1.5">Title</label>
                <input
                  id="init-title"
                  type="text"
                  value={title()}
                  onInput={(e) => setTitle(e.currentTarget.value)}
                  class={inputClass}
                  placeholder="What is the one thing your team will focus on?"
                  autofocus
                />
              </div>

              <div>
                <label for="init-desc" class="block text-sm font-medium text-ctp-subtext1 mb-1.5">
                  Description <span class="text-ctp-overlay0 font-normal">(optional)</span>
                </label>
                <textarea
                  id="init-desc"
                  value={description()}
                  onInput={(e) => setDescription(e.currentTarget.value)}
                  rows="3"
                  class={`${inputClass} resize-none`}
                  placeholder="Brief description of the initiative"
                />
              </div>

              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label for="init-budget" class="block text-sm font-medium text-ctp-subtext1 mb-1.5">
                    Time budget <span class="text-ctp-overlay0 font-normal">(days)</span>
                  </label>
                  <input
                    id="init-budget"
                    type="number"
                    value={timeBudget()}
                    onInput={(e) => setTimeBudget(e.currentTarget.value)}
                    min="0"
                    step="0.5"
                    class={inputClass}
                    placeholder="e.g. 5"
                  />
                </div>
                <div>
                  <label for="init-chat" class="block text-sm font-medium text-ctp-subtext1 mb-1.5">
                    Chat room link <span class="text-ctp-overlay0 font-normal">(optional)</span>
                  </label>
                  <input
                    id="init-chat"
                    type="url"
                    value={chatRoomLink()}
                    onInput={(e) => setChatRoomLink(e.currentTarget.value)}
                    class={inputClass}
                    placeholder="https://..."
                  />
                </div>
              </div>
            </div>

            {/* Footer */}
            <div class="flex items-center justify-end gap-3 px-6 py-4 border-t border-ctp-surface0">
              <Dialog.CloseButton class="px-4 py-2 rounded-lg border border-ctp-surface1 text-ctp-subtext1 hover:text-ctp-text hover:bg-ctp-surface0 text-sm font-medium transition-colors">
                Cancel
              </Dialog.CloseButton>
              <button
                onClick={create}
                disabled={loading() || title().trim() === ""}
                class="px-4 py-2 rounded-lg bg-ctp-mauve text-ctp-base text-sm font-medium hover:opacity-90 disabled:opacity-50 transition-colors"
              >
                {loading() ? "Creating..." : "Create initiative"}
              </button>
            </div>
          </Dialog.Content>
        </div>
      </Dialog.Portal>
    </Dialog>
  );
};

// --- Zero State ---

const ZeroState: Component<{ productName: string; onCreate: () => void }> = (props) => (
  <div class="flex flex-col items-center justify-center min-h-[60vh]">
    <div class="relative mb-8">
      <div class="absolute inset-0 -m-4 rounded-full border border-ctp-surface0/50" />
      <div class="absolute inset-0 -m-9 rounded-full border border-ctp-surface0/30" />
      <div class="size-20 rounded-full bg-gradient-to-br from-ctp-mauve/20 to-ctp-blue/20 flex items-center justify-center">
        <TbOutlineRocket size={36} class="text-ctp-mauve" />
      </div>
    </div>
    <h2 class="text-xl font-semibold text-ctp-text mt-4 mb-2">No initiatives yet</h2>
    <p class="text-sm text-ctp-subtext0 text-center max-w-md mb-2 leading-relaxed">
      Initiatives are the <span class="text-ctp-text font-medium">one thing</span> your team focuses on at a time.
    </p>
    <p class="text-sm text-ctp-subtext0 text-center max-w-md mb-8 leading-relaxed">
      Create your first initiative for <span class="text-ctp-mauve font-medium">{props.productName}</span> to get started.
    </p>
    <button
      onClick={props.onCreate}
      class="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-ctp-mauve text-ctp-base font-medium hover:opacity-90 transition-all hover:shadow-lg hover:shadow-ctp-mauve/20"
    >
      <FiPlus size={16} />
      <span>Create first initiative</span>
    </button>
    <div class="flex items-center gap-4 mt-6 text-xs text-ctp-overlay0">
      <span class="flex items-center gap-1.5"><FiTarget size={14} /> Focus</span>
      <span class="text-ctp-surface1">/</span>
      <span class="flex items-center gap-1.5"><FiBarChart2 size={14} /> Score</span>
      <span class="text-ctp-surface1">/</span>
      <span class="flex items-center gap-1.5"><FiCheckCircle size={14} /> Ship</span>
    </div>
  </div>
);

// --- Initiative Card ---

const InitiativeCard: Component<{ initiative: Initiative }> = (props) => {
  const i = props.initiative;
  const progress = () => statusColors[i.progressStatus] ?? statusColors.thinking;
  const lifecycle = () => lifecycleColors[i.lifecycleStatus] ?? lifecycleColors.waiting;

  return (
    <a
      href={`/app/initiatives/${i.slug}`}
      class="block p-4 rounded-lg border border-ctp-surface0 bg-ctp-mantle hover:border-ctp-surface1 hover:bg-ctp-surface0/50 transition-colors group"
    >
      <div class="flex items-start justify-between gap-3">
        <div class="min-w-0 flex-1">
          <h3 class="text-sm font-medium text-ctp-text group-hover:text-ctp-mauve transition-colors truncate">
            {i.title}
          </h3>
          <Show when={i.description}>
            <p class="text-xs text-ctp-subtext0 mt-1 line-clamp-1">{i.description}</p>
          </Show>
        </div>
        <div class="flex items-center gap-2 shrink-0">
          <span class={`inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium capitalize ${lifecycle()}`}>
            {i.lifecycleStatus}
          </span>
          <span class={`inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium capitalize ${progress()}`}>
            {i.progressStatus}
          </span>
        </div>
      </div>
      <Show when={i.score}>
        <div class="flex items-center gap-3 mt-2.5">
          <span class="text-[11px] text-ctp-subtext0">
            Score: {i.score!.scoreType === "proxy" ? "Proxy" : "Break-even"}
          </span>
          <Show when={i.score!.isCore}>
            <span class="text-[11px] text-ctp-peach font-medium">Core</span>
          </Show>
        </div>
      </Show>
    </a>
  );
};

// --- Main Page Component ---

const InitiativesPage: Component<Props> = (props) => {
  const [showCreate, setShowCreate] = createSignal(false);

  return (
    <div>
      {/* Header */}
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-xl font-bold text-ctp-text">Initiatives</h1>
          <p class="text-sm text-ctp-subtext0 mt-0.5">{props.currentProduct.name}</p>
        </div>
        <Show when={props.initiatives.length > 0}>
          <button
            onClick={() => setShowCreate(true)}
            class="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-ctp-mauve text-ctp-base text-sm font-medium hover:opacity-90 transition-colors"
          >
            <FiPlus size={16} />
            <span>New initiative</span>
          </button>
        </Show>
      </div>

      {/* Zero state */}
      <Show when={props.initiatives.length === 0}>
        <ZeroState
          productName={props.currentProduct.name}
          onCreate={() => setShowCreate(true)}
        />
      </Show>

      {/* Initiative list */}
      <Show when={props.initiatives.length > 0}>
        <div class="space-y-2">
          <For each={props.initiatives}>
            {(initiative) => <InitiativeCard initiative={initiative} />}
          </For>
        </div>
      </Show>

      {/* Create dialog */}
      <CreateInitiativeDialog
        open={showCreate()}
        onOpenChange={setShowCreate}
        productId={props.currentProduct.productId}
      />
    </div>
  );
};

export default InitiativesPage;
