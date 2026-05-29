<script lang="ts">
  // Bottom composer for sending a chat message.
  import IconButton from '$lib/components/ui/IconButton.svelte';

  interface Props {
    onsend: (text: string) => void | Promise<void>;
    disabled?: boolean;
    placeholder?: string;
    class?: string;
  }
  const { onsend, disabled = false, placeholder = 'Nachricht schreiben…', class: klass = '' }: Props = $props();

  let text = $state('');
  let sending = $state(false);

  async function submit() {
    const value = text.trim();
    if (!value || sending || disabled) return;
    sending = true;
    try {
      await onsend(value);
      text = '';
    } finally {
      sending = false;
    }
  }

  function onkeydown(e: KeyboardEvent) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      submit();
    }
  }
</script>

<form
  class="flex items-end gap-sm border-t border-outline-variant bg-surface-container-lowest p-sm {klass}"
  onsubmit={(e) => {
    e.preventDefault();
    submit();
  }}
>
  <textarea
    bind:value={text}
    {onkeydown}
    {placeholder}
    rows="1"
    class="font-body-md text-body-md max-h-40 flex-1 resize-none rounded-2xl border border-outline-variant bg-surface-container-lowest px-md py-sm text-on-surface placeholder:text-on-surface-variant focus:border-primary focus:outline-none"
    disabled={disabled || sending}
  ></textarea>
  <IconButton
    icon="send"
    label="Senden"
    onclick={submit}
    disabled={disabled || sending || !text.trim()}
  />
</form>
