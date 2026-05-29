<script lang="ts">
  import TextField from './TextField.svelte';

  interface Props {
    label?: string;
    helper?: string;
    error?: string | null;
    value?: string;
    id?: string;
    name?: string;
    required?: boolean;
    disabled?: boolean;
    class?: string;
  }
  let { value = $bindable(''), ...rest }: Props = $props();
</script>

<TextField type="time" leadingIcon="schedule" bind:value {...rest} />
