<script lang="ts">
  interface Props {
    class?: string;
  }
  const { class: klass = '' }: Props = $props();
  const year = new Date().getFullYear();
</script>

<footer
  class="border-t border-outline-variant bg-surface-container-lowest px-md py-md text-center text-on-surface-variant {klass}"
>
  <div
    class="mx-auto flex max-w-screen-xl flex-col items-center gap-xs sm:flex-row sm:justify-between"
  >
    <p class="font-label-md text-label-md">© {year} ActNow</p>
    <nav class="flex flex-wrap items-center gap-md text-[13px]">
      <a href="/impressum" class="hover:text-primary">Impressum</a>
      <a href="/datenschutz" class="hover:text-primary">Datenschutz</a>
      <a href="/agb" class="hover:text-primary">Demo-Hinweise</a>
    </nav>
  </div>
</footer>
