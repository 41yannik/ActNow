<script lang="ts">
  interface Props {
    size?: number;
    label?: string;
    class?: string;
  }
  let { size = 24, label = 'Lädt …', class: klass = '' }: Props = $props();
</script>

<span class="inline-flex items-center gap-xs {klass}" role="status">
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    class="animate-spin text-primary"
    aria-hidden="true"
  >
    <circle
      cx="12"
      cy="12"
      r="9"
      stroke="currentColor"
      stroke-width="3"
      fill="none"
      stroke-linecap="round"
      stroke-dasharray="42"
      stroke-dashoffset="14"
      opacity="0.85"
    />
  </svg>
  <span class="sr-only">{label}</span>
</span>
