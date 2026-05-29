// Toast store. Reactive list of transient notifications.
export type ToastTone = 'info' | 'success' | 'warning' | 'error';

export interface Toast {
  id: number;
  tone: ToastTone;
  title?: string;
  message: string;
  /** Auto-dismiss after this many ms. Set to 0 to keep until dismissed. */
  duration: number;
}

const items = $state<Toast[]>([]);
let nextId = 1;

function push(tone: ToastTone, message: string, title?: string, duration = 4000): number {
  const id = nextId++;
  items.push({ id, tone, message, title, duration });
  if (duration > 0) {
    setTimeout(() => dismiss(id), duration);
  }
  return id;
}

function dismiss(id: number) {
  const idx = items.findIndex((t) => t.id === id);
  if (idx >= 0) items.splice(idx, 1);
}

export const toasts = {
  get items() {
    return items;
  },
  dismiss,
  info: (message: string, title?: string, duration?: number) =>
    push('info', message, title, duration),
  success: (message: string, title?: string, duration?: number) =>
    push('success', message, title, duration),
  warning: (message: string, title?: string, duration?: number) =>
    push('warning', message, title, duration),
  error: (message: string, title?: string, duration = 6000) =>
    push('error', message, title, duration)
};
