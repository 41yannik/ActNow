<script lang="ts">
  import Icon from './Icon.svelte';

  interface Props {
    category: string;
    dark?: boolean;
    class?: string;
  }

  let { category, dark = false, class: klass = '' }: Props = $props();

  interface CategoryConfig {
    color: string;
    bg: string;
    icon: string;
  }

  const configs: Record<string, CategoryConfig> = {
    Umwelt: { color: '#4F6B3E', bg: 'rgba(95,110,77,0.92)', icon: 'eco' },
    Tiere: { color: '#7A5536', bg: 'rgba(122,85,54,0.92)', icon: 'pets' },
    Soziales: { color: '#5B7AAE', bg: 'rgba(91,122,174,0.92)', icon: 'group' },
    Bildung: { color: '#8B6B3D', bg: 'rgba(139,107,61,0.92)', icon: 'school' },
    Food: { color: '#A86C3F', bg: 'rgba(168,108,63,0.92)', icon: 'restaurant' },
    Senioren: { color: '#8D5A8A', bg: 'rgba(141,90,138,0.92)', icon: 'elderly' },
    Kinder: { color: '#C28A4F', bg: 'rgba(194,138,79,0.92)', icon: 'child_care' },
    Events: { color: '#5F6E4D', bg: 'rgba(95,110,77,0.92)', icon: 'celebration' },
  };

  // Fallback if category is not in list
  const fallback: CategoryConfig = {
    color: '#5F6E4D',
    bg: 'rgba(95,110,77,0.92)',
    icon: 'volunteer_activism',
  };

  const config = $derived(configs[category] ?? fallback);
</script>

<div
  class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-[12px] font-semibold transition-all shadow-sm {klass}"
  style="
    background: {dark ? config.bg : '#ffffff'};
    color: {dark ? '#ffffff' : config.color};
    box-shadow: {dark ? 'none' : '0 1px 3px rgba(0,0,0,0.12)'};
  "
>
  <Icon name={config.icon} size={13} />
  <span>{category}</span>
</div>
