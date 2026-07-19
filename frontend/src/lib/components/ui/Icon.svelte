<script lang="ts">
  // Material Symbols Outlined wrapper.
  // The font is bundled locally through Fontsource in the root layout.
  interface Props {
    name: string;
    filled?: boolean;
    size?: number;
    /** Extra Tailwind / utility classes (color, etc.). */
    class?: string;
    'aria-hidden'?: boolean;
  }
  let {
    name,
    filled = false,
    size = 20,
    class: klass = '',
    'aria-hidden': ariaHidden = true,
  }: Props = $props();
</script>

<span
  class="material-symbols-outlined select-none leading-none {klass}"
  style="font-size:{size}px;{filled ? `font-variation-settings:'FILL' 1;` : ''}"
  aria-hidden={ariaHidden}
>
  {name}
</span>
