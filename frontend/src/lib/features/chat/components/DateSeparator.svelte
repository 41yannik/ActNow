<script lang="ts">
  import { formatDate } from '$lib/utils/format';

  interface Props {
    date: string;
    class?: string;
  }
  const { date, class: klass = '' }: Props = $props();
</script>

<div class="my-sm flex items-center gap-sm {klass}" aria-hidden="false">
  <span class="h-px flex-1 bg-outline-variant"></span>
  <span class="text-[12px] text-on-surface-variant">{formatDate(date)}</span>
  <span class="h-px flex-1 bg-outline-variant"></span>
</div>
