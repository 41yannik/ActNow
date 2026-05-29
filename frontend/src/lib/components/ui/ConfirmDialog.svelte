<script lang="ts">
  import Modal from './Modal.svelte';
  import Button from './Button.svelte';

  interface Props {
    open: boolean;
    title: string;
    message: string;
    confirmLabel?: string;
    cancelLabel?: string;
    tone?: 'primary' | 'danger';
    onconfirm: () => void | Promise<void>;
    oncancel?: () => void;
  }

  let {
    open = $bindable(),
    title,
    message,
    confirmLabel = 'Bestätigen',
    cancelLabel = 'Abbrechen',
    tone = 'primary',
    onconfirm,
    oncancel
  }: Props = $props();

  let busy = $state(false);

  async function confirm() {
    busy = true;
    try {
      await onconfirm();
      open = false;
    } finally {
      busy = false;
    }
  }

  function cancel() {
    oncancel?.();
    open = false;
  }
</script>

<Modal bind:open {title} size="sm" onclose={cancel}>
  <p class="font-body-md text-body-md text-on-surface-variant">{message}</p>
  {#snippet footer()}
    <Button variant="text" onclick={cancel} disabled={busy}>{cancelLabel}</Button>
    <Button
      variant={tone === 'danger' ? 'danger' : 'primary'}
      onclick={confirm}
      loading={busy}
    >
      {confirmLabel}
    </Button>
  {/snippet}
</Modal>
