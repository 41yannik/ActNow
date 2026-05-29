<script lang="ts">
  import Icon from '../ui/Icon.svelte';
  import Button from '../ui/Button.svelte';

  export interface UploadedFile {
    file: File;
    name: string;
    size: number;
    type: string;
  }

  interface Props {
    label?: string;
    helper?: string;
    error?: string | null;
    /** MIME types or extensions accepted, e.g. "image/*,.pdf". */
    accept?: string;
    multiple?: boolean;
    /** Max size in bytes per file (default 20 MB). */
    maxSize?: number;
    /** Currently selected files (bindable). */
    files?: UploadedFile[];
    /** Fires whenever the file list changes. */
    onchange?: (files: UploadedFile[]) => void;
    class?: string;
  }

  let {
    label,
    helper,
    error = null,
    accept,
    multiple = false,
    maxSize = 20 * 1024 * 1024,
    files = $bindable([]),
    onchange,
    class: klass = ''
  }: Props = $props();

  let dragging = $state(false);
  let internalError = $state<string | null>(null);
  let input: HTMLInputElement | undefined = $state();
  const message = $derived(error ?? internalError);

  function intake(list: FileList | null) {
    if (!list || list.length === 0) return;
    const next: UploadedFile[] = [];
    for (const f of Array.from(list)) {
      if (f.size > maxSize) {
        internalError = `Datei "${f.name}" überschreitet das Limit von ${Math.round(maxSize / 1024 / 1024)} MB.`;
        return;
      }
      next.push({ file: f, name: f.name, size: f.size, type: f.type });
    }
    internalError = null;
    files = multiple ? [...files, ...next] : next;
    onchange?.(files);
  }

  function onDrop(e: DragEvent) {
    e.preventDefault();
    dragging = false;
    intake(e.dataTransfer?.files ?? null);
  }

  function onDragOver(e: DragEvent) {
    e.preventDefault();
    dragging = true;
  }

  function remove(idx: number) {
    files = files.filter((_, i) => i !== idx);
    onchange?.(files);
  }

  function humanSize(b: number): string {
    if (b < 1024) return `${b} B`;
    if (b < 1024 * 1024) return `${(b / 1024).toFixed(1)} KB`;
    return `${(b / 1024 / 1024).toFixed(1)} MB`;
  }
</script>

<div class="w-full {klass}">
  {#if label}
    <p class="block font-label-md text-label-md text-on-surface-variant mb-1">{label}</p>
  {/if}
  <button
    type="button"
    class="flex w-full flex-col items-center justify-center gap-xs rounded-2xl border-2 border-dashed px-md py-lg text-center transition-colors {dragging ? 'border-primary bg-primary-container/40' : message ? 'border-error bg-error-container/20' : 'border-outline-variant bg-surface-container-low hover:bg-surface-container'}"
    ondragover={onDragOver}
    ondragleave={() => (dragging = false)}
    ondrop={onDrop}
    onclick={() => input?.click()}
  >
    <Icon name="cloud_upload" size={28} class="text-primary" />
    <p class="font-label-md text-label-md text-on-surface">Datei hierher ziehen oder klicken</p>
    {#if helper}
      <p class="text-[13px] text-on-surface-variant">{helper}</p>
    {/if}
  </button>
  <input
    bind:this={input}
    type="file"
    {accept}
    {multiple}
    class="hidden"
    onchange={(e) => intake((e.currentTarget as HTMLInputElement).files)}
  />
  {#if files.length > 0}
    <ul class="mt-sm space-y-1">
      {#each files as f, i (f.name + i)}
        <li class="flex items-center gap-sm rounded-lg bg-surface-container-low px-sm py-2">
          <Icon name="description" size={20} class="text-primary" />
          <div class="min-w-0 flex-1">
            <p class="truncate font-label-md text-label-md text-on-surface">{f.name}</p>
            <p class="text-[12px] text-on-surface-variant">{humanSize(f.size)}</p>
          </div>
          <Button variant="text" size="sm" leadingIcon="delete" onclick={() => remove(i)}>
            Entfernen
          </Button>
        </li>
      {/each}
    </ul>
  {/if}
  {#if message}
    <p class="mt-1 text-[13px] text-error font-label-md">{message}</p>
  {/if}
</div>
