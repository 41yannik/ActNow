<script lang="ts">
  interface Props {
    label: string;
    checked?: boolean;
    name?: string;
    value?: string;
    disabled?: boolean;
    class?: string;
  }
  let {
    label,
    checked = $bindable(false),
    name,
    value,
    disabled = false,
    class: klass = ''
  }: Props = $props();
</script>

<label
  class="inline-flex items-center gap-2 font-body-md text-body-md text-on-surface cursor-pointer {klass}"
>
  <input
    type="checkbox"
    bind:checked
    {name}
    {value}
    {disabled}
    class="rounded text-primary focus:ring-primary h-4 w-4 border-outline"
  />
  <span>{label}</span>
</label>
