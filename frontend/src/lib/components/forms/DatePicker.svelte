<script lang="ts">
  import TextField from './TextField.svelte';

  interface Props {
    label?: string;
    helper?: string;
    error?: string | null;
    value?: string;
    id?: string;
    name?: string;
    min?: string;
    max?: string;
    required?: boolean;
    disabled?: boolean;
    class?: string;
  }
  let { value = $bindable(''), ...rest }: Props = $props();
</script>

<TextField type="date" leadingIcon="calendar_today" bind:value {...rest} />
