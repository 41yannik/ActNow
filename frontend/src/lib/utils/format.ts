// German-locale formatting helpers.

const DATE_FMT = new Intl.DateTimeFormat('de-DE', {
  day: '2-digit',
  month: '2-digit',
  year: 'numeric'
});

const TIME_FMT = new Intl.DateTimeFormat('de-DE', {
  hour: '2-digit',
  minute: '2-digit'
});

const DATETIME_FMT = new Intl.DateTimeFormat('de-DE', {
  day: '2-digit',
  month: 'short',
  year: 'numeric',
  hour: '2-digit',
  minute: '2-digit'
});

const WEEKDAY_FMT = new Intl.DateTimeFormat('de-DE', { weekday: 'long' });
const MONTH_YEAR_FMT = new Intl.DateTimeFormat('de-DE', {
  month: 'long',
  year: 'numeric'
});

export function formatDate(iso: string | Date | null | undefined): string {
  if (!iso) return '';
  return DATE_FMT.format(new Date(iso));
}

export function formatTime(iso: string | Date | null | undefined): string {
  if (!iso) return '';
  return TIME_FMT.format(new Date(iso));
}

export function formatDateTime(iso: string | Date | null | undefined): string {
  if (!iso) return '';
  return DATETIME_FMT.format(new Date(iso));
}

export function formatWeekday(iso: string | Date): string {
  return WEEKDAY_FMT.format(new Date(iso));
}

export function formatMonthYear(iso: string | Date): string {
  return MONTH_YEAR_FMT.format(new Date(iso));
}

/** "vor 2 Std", "vor 3 Tagen", "gerade eben" */
export function formatRelative(iso: string | Date | null | undefined): string {
  if (!iso) return '';
  const d = new Date(iso).getTime();
  const diff = Date.now() - d;
  const sec = Math.round(diff / 1000);
  if (sec < 45) return 'gerade eben';
  const min = Math.round(sec / 60);
  if (min < 60) return `vor ${min} Min`;
  const hr = Math.round(min / 60);
  if (hr < 24) return `vor ${hr} Std`;
  const day = Math.round(hr / 24);
  if (day < 7) return `vor ${day} ${day === 1 ? 'Tag' : 'Tagen'}`;
  return formatDate(iso);
}

/** Initials from a display name: "Anna Schmidt" -> "AS" */
export function initials(name: string | null | undefined, max = 2): string {
  if (!name) return '?';
  return name
    .trim()
    .split(/\s+/)
    .slice(0, max)
    .map((p) => p[0]?.toUpperCase() ?? '')
    .join('');
}

/** Locale-aware count: "1 Bewerbung" / "5 Bewerbungen" */
export function pluralize(n: number, singular: string, plural: string): string {
  return `${n} ${n === 1 ? singular : plural}`;
}
