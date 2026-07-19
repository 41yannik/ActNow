import { toasts } from '$lib/stores/toasts.svelte';

export const DEMO_ACTION_MESSAGE =
  'Interaktive Demo: Änderungen werden nicht gespeichert oder übertragen.';

export function showDemoAction(action?: string): void {
  toasts.info(DEMO_ACTION_MESSAGE, action ? `${action} ist deaktiviert` : 'Nur Ansicht');
}
