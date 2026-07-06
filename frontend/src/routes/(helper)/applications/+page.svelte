<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import SageHeader from '$lib/components/layout/SageHeader.svelte';
  import Alert from '$lib/components/ui/Alert.svelte';
  import Badge from '$lib/components/ui/Badge.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import ConfirmDialog from '$lib/components/ui/ConfirmDialog.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
  import Icon from '$lib/components/ui/Icon.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import Tabs from '$lib/components/ui/Tabs.svelte';
  import {
    listApplicationsForHelper,
    withdrawApplication,
  } from '$lib/services/supabase/applications';
  import { getCommunitySummary } from '$lib/services/supabase/messages';
  import { getOrCreateConversationForApplication } from '$lib/services/supabase/messages';
  import { listApplicationNotifications } from '$lib/services/supabase/notifications';
  import { auth } from '$lib/stores/auth.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import { APPLICATION_STATUS_LABEL, OFFER_STATUS_LABEL } from '$lib/utils/labels';
  import { formatDate, formatDateTime, formatRelative } from '$lib/utils/format';
  import type {
    ApplicationStatus,
    ApplicationWithOffer,
    NotificationRow,
  } from '$lib/types/database';

  type TabValue = 'applications' | 'assignments' | 'history';
  type TimelineTone = 'done' | 'current' | 'muted';
  type ReminderState = 'planned' | 'due' | 'sent';

  interface TimelineEntry {
    id: string;
    label: string;
    detail: string;
    at: string;
    icon: string;
    tone: TimelineTone;
    future?: boolean;
  }

  interface AssignmentReminder {
    id: string;
    applicationId: string;
    offerTitle: string;
    label: string;
    scheduledAt: string;
    sentAt: string | null;
    state: ReminderState;
    icon: string;
    detail: string;
  }

  const APPLICATION_STATUSES = new Set<ApplicationStatus>(['submitted', 'shortlisted']);
  const ASSIGNMENT_STATUSES = new Set<ApplicationStatus>(['accepted']);
  const HISTORY_STATUSES = new Set<ApplicationStatus>([
    'rejected',
    'withdrawn',
    'cancelled',
    'completed',
    'no_show',
  ]);
  const WITHDRAWABLE_STATUSES = new Set<ApplicationStatus>([
    'submitted',
    'shortlisted',
    'accepted',
  ]);
  const REMINDER_OFFSETS = [
    { key: '24h', label: '24h vorher', hours: 24, icon: 'notifications_active' },
    { key: '2h', label: '2h vorher', hours: 2, icon: 'alarm' },
  ] as const;
  const REMINDER_STATE_LABEL: Record<ReminderState, string> = {
    planned: 'Geplant',
    due: 'Fällig',
    sent: 'Gesendet',
  };

  let loading = $state(true);
  let rows = $state<ApplicationWithOffer[]>([]);
  let applicationNotifications = $state<NotificationRow[]>([]);
  let activeTab = $state<TabValue>('applications');
  let errorMessage = $state<string | null>(null);
  let selectedForWithdraw = $state<ApplicationWithOffer | null>(null);
  let withdrawDialogOpen = $state(false);
  let busyIds = $state<Set<string>>(new Set());
  let summary = $state({ unread_messages: 0, unread_notifications: 0, total_unread: 0 });

  const tabs = [
    { value: 'applications', label: 'Bewerbungen', icon: 'how_to_reg' },
    { value: 'assignments', label: 'Einsätze', icon: 'event_available' },
    { value: 'history', label: 'Historie', icon: 'history' },
  ] satisfies Array<{ value: TabValue; label: string; icon: string }>;

  const applications = $derived(rows.filter((row) => APPLICATION_STATUSES.has(row.status)));
  const assignments = $derived(rows.filter((row) => ASSIGNMENT_STATUSES.has(row.status)));
  const history = $derived(rows.filter((row) => HISTORY_STATUSES.has(row.status)));
  const visibleRows = $derived(
    activeTab === 'applications'
      ? applications
      : activeTab === 'assignments'
        ? assignments
        : history,
  );
  const notificationsByApplication = $derived.by(() => {
    const grouped = new Map<string, NotificationRow[]>();
    for (const notification of applicationNotifications) {
      if (notification.entity_type !== 'application' || !notification.entity_id) continue;
      const existing = grouped.get(notification.entity_id) ?? [];
      existing.push(notification);
      grouped.set(notification.entity_id, existing);
    }
    return grouped;
  });
  const nextAssignment = $derived.by(
    () =>
      assignments
        .filter((row) => row.offer?.starts_at)
        .sort(
          (a, b) =>
            new Date(a.offer!.starts_at!).getTime() - new Date(b.offer!.starts_at!).getTime(),
        )[0] ?? null,
  );
  const assignmentReminders = $derived.by(() =>
    assignments
      .flatMap((row) => buildReminderPlans(row, notificationsFor(row)))
      .sort(
        (a, b) =>
          new Date(a.sentAt ?? a.scheduledAt).getTime() -
          new Date(b.sentAt ?? b.scheduledAt).getTime(),
      )
      .slice(0, 4),
  );

  function setBusy(id: string, busy: boolean) {
    const next = new Set(busyIds);
    if (busy) next.add(id);
    else next.delete(id);
    busyIds = next;
  }

  async function load() {
    if (!auth.profile) return;
    loading = true;
    errorMessage = null;
    try {
      const [apps, unread] = await Promise.all([
        listApplicationsForHelper(auth.profile.id),
        getCommunitySummary().catch(() => summary),
      ]);
      const relatedNotifications = await listApplicationNotifications(
        apps.map((app) => app.id),
        Math.max(60, apps.length * 6),
      ).catch(() => []);
      rows = apps;
      applicationNotifications = relatedNotifications;
      summary = unread;
    } catch (err) {
      errorMessage =
        err instanceof Error ? err.message : 'Bewerbungen konnten nicht geladen werden.';
      toasts.error(errorMessage);
    } finally {
      loading = false;
    }
  }

  onMount(load);

  function organizationName(row: ApplicationWithOffer): string {
    return row.offer?.organization?.profile.display_name ?? 'Organisation';
  }

  function title(row: ApplicationWithOffer): string {
    return row.offer?.title ?? 'Angebot nicht mehr verfügbar';
  }

  function location(row: ApplicationWithOffer): string {
    if (!row.offer) return 'Keine Ortsdaten';
    if (row.offer.is_remote) return 'Remote';
    return row.offer.city ?? row.offer.location_name ?? 'Vor Ort';
  }

  function schedule(row: ApplicationWithOffer): string {
    if (!row.offer?.starts_at) return 'Termin nach Absprache';
    if (!row.offer.ends_at) return formatDateTime(row.offer.starts_at);
    return `${formatDateTime(row.offer.starts_at)} - ${formatDateTime(row.offer.ends_at)}`;
  }

  function submittedLine(row: ApplicationWithOffer): string {
    return `Beworben ${formatRelative(row.submitted_at)}`;
  }

  function statusHint(row: ApplicationWithOffer): string {
    if (row.status === 'submitted') return 'Die Organisation prueft deine Bewerbung.';
    if (row.status === 'shortlisted') return 'Du bist in der engeren Auswahl.';
    if (row.status === 'accepted') return 'Du bist eingeplant. Halte dir den Termin frei.';
    if (row.status === 'rejected') return 'Die Organisation hat sich anders entschieden.';
    if (row.status === 'withdrawn') return 'Du hast deine Bewerbung zurueckgezogen.';
    if (row.status === 'completed') return 'Dieser Einsatz ist abgeschlossen.';
    if (row.status === 'cancelled') return 'Dieser Einsatz wurde storniert.';
    if (row.status === 'no_show') return 'Du wurdest als nicht erschienen markiert.';
    return 'Status aktualisiert.';
  }

  function statusDate(row: ApplicationWithOffer): string | null {
    const iso =
      row.status === 'accepted'
        ? row.accepted_at
        : row.status === 'rejected'
          ? row.rejected_at
          : row.status === 'withdrawn'
            ? row.withdrawn_at
            : row.status === 'completed'
              ? row.completed_at
              : row.submitted_at;
    return iso ? formatDate(iso) : null;
  }

  function notificationsFor(row: ApplicationWithOffer): NotificationRow[] {
    return notificationsByApplication.get(row.id) ?? [];
  }

  function notificationFor(row: ApplicationWithOffer, type: string): NotificationRow | null {
    return notificationsFor(row).find((notification) => notification.type === type) ?? null;
  }

  function statusEvent(
    row: ApplicationWithOffer,
    status: ApplicationStatus,
    at: string | null,
    fallbackDetail: string,
    tone: TimelineTone,
  ): TimelineEntry | null {
    if (!at) return null;
    const notification = notificationFor(row, `application.${status}`);
    return {
      id: `${row.id}-${status}`,
      label: APPLICATION_STATUS_LABEL[status],
      detail: notification?.body ?? fallbackDetail,
      at: notification?.created_at ?? at,
      icon: statusIcon(status),
      tone,
    };
  }

  function statusIcon(status: ApplicationStatus): string {
    if (status === 'submitted') return 'send';
    if (status === 'shortlisted') return 'filter_alt';
    if (status === 'accepted') return 'event_available';
    if (status === 'rejected') return 'block';
    if (status === 'withdrawn') return 'undo';
    if (status === 'completed') return 'task_alt';
    if (status === 'cancelled') return 'event_busy';
    if (status === 'no_show') return 'person_off';
    return 'history';
  }

  function timeline(row: ApplicationWithOffer): TimelineEntry[] {
    const entries: TimelineEntry[] = [
      {
        id: `${row.id}-submitted`,
        label: APPLICATION_STATUS_LABEL.submitted,
        detail: 'Deine Bewerbung wurde an die Organisation gesendet.',
        at: row.submitted_at,
        icon: 'send',
        tone: 'done',
      },
    ];

    const shortlistedNote = notificationFor(row, 'application.shortlisted');
    if (row.status === 'shortlisted' || shortlistedNote) {
      entries.push({
        id: `${row.id}-shortlisted`,
        label: APPLICATION_STATUS_LABEL.shortlisted,
        detail:
          shortlistedNote?.body ?? 'Die Organisation hat dich in die engere Auswahl genommen.',
        at: shortlistedNote?.created_at ?? row.updated_at,
        icon: 'filter_alt',
        tone: row.status === 'shortlisted' ? 'current' : 'done',
      });
    }

    const statusEvents = [
      statusEvent(
        row,
        'accepted',
        row.accepted_at,
        'Du bist fuer diesen Einsatz eingeplant.',
        row.status === 'accepted' ? 'current' : 'done',
      ),
      statusEvent(
        row,
        'rejected',
        row.rejected_at,
        'Die Organisation hat deine Bewerbung abgesagt.',
        row.status === 'rejected' ? 'current' : 'done',
      ),
      statusEvent(
        row,
        'withdrawn',
        row.withdrawn_at,
        'Du hast deine Bewerbung zurueckgezogen.',
        row.status === 'withdrawn' ? 'current' : 'done',
      ),
      statusEvent(
        row,
        'completed',
        row.completed_at,
        'Der Einsatz wurde abgeschlossen.',
        row.status === 'completed' ? 'current' : 'done',
      ),
    ].filter((entry): entry is TimelineEntry => Boolean(entry));

    entries.push(...statusEvents);

    if (row.status === 'cancelled' || row.status === 'no_show') {
      entries.push({
        id: `${row.id}-${row.status}`,
        label: APPLICATION_STATUS_LABEL[row.status],
        detail: notificationFor(row, `application.${row.status}`)?.body ?? statusHint(row),
        at: notificationFor(row, `application.${row.status}`)?.created_at ?? row.updated_at,
        icon: statusIcon(row.status),
        tone: 'current',
      });
    }

    for (const reminder of buildReminderPlans(row, notificationsFor(row))) {
      entries.push({
        id: reminder.id,
        label: reminder.label,
        detail: reminder.detail,
        at: reminder.sentAt ?? reminder.scheduledAt,
        icon: reminder.icon,
        tone: reminder.state === 'sent' ? 'done' : reminder.state === 'due' ? 'current' : 'muted',
        future: reminder.state === 'planned',
      });
    }

    return entries.sort((a, b) => new Date(a.at).getTime() - new Date(b.at).getTime());
  }

  function buildReminderPlans(
    row: ApplicationWithOffer,
    notifications: NotificationRow[],
  ): AssignmentReminder[] {
    if (row.status !== 'accepted' || !row.offer?.starts_at) return [];
    const startsAt = new Date(row.offer.starts_at).getTime();
    if (!Number.isFinite(startsAt)) return [];

    return REMINDER_OFFSETS.map((offset) => {
      const type = `assignment.reminder.${offset.key}`;
      const sent = notifications.find((notification) => notification.type === type) ?? null;
      const scheduledAt = new Date(startsAt - offset.hours * 60 * 60 * 1000).toISOString();
      const state: ReminderState = sent
        ? 'sent'
        : Date.now() >= new Date(scheduledAt).getTime()
          ? 'due'
          : 'planned';
      return {
        id: `${row.id}-${type}`,
        applicationId: row.id,
        offerTitle: title(row),
        label: offset.label,
        scheduledAt,
        sentAt: sent?.created_at ?? null,
        state,
        icon: offset.icon,
        detail:
          sent?.body ??
          (state === 'due'
            ? 'Dieser Reminder ist jetzt faellig.'
            : `Reminder wird fuer ${formatDateTime(scheduledAt)} gefuehrt.`),
      };
    });
  }

  function timelineToneClass(tone: TimelineTone): string {
    if (tone === 'done') return 'bg-primary text-on-primary';
    if (tone === 'current') return 'bg-tertiary text-on-tertiary';
    return 'bg-surface-container-high text-on-surface-variant';
  }

  function reminderStateClass(state: ReminderState): string {
    if (state === 'sent') return 'bg-primary-container text-on-primary-container';
    if (state === 'due') return 'bg-tertiary-container text-on-tertiary-container';
    return 'bg-surface-container-high text-on-surface-variant';
  }

  async function openChat(row: ApplicationWithOffer) {
    setBusy(row.id, true);
    try {
      const conversation = await getOrCreateConversationForApplication(row.id);
      await goto(`/messages/${conversation.id}`);
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Chat konnte nicht geöffnet werden.');
    } finally {
      setBusy(row.id, false);
    }
  }

  async function confirmWithdraw() {
    const row = selectedForWithdraw;
    if (!row) return;
    setBusy(row.id, true);
    try {
      const updated = await withdrawApplication(row.id);
      rows = rows.map((item) =>
        item.id === row.id ? { ...item, ...updated, offer: item.offer } : item,
      );
      selectedForWithdraw = null;
      withdrawDialogOpen = false;
      activeTab = 'history';
      toasts.success('Bewerbung zurückgezogen', title(row));
    } catch (err) {
      toasts.error(
        err instanceof Error ? err.message : 'Bewerbung konnte nicht zurückgezogen werden.',
      );
    } finally {
      setBusy(row.id, false);
    }
  }
</script>

<svelte:head><title>Bewerbungen & Einsätze · ActNow</title></svelte:head>

<section class="mx-auto flex w-full max-w-4xl flex-col pb-28 md:pb-md">
  <SageHeader
    title="Einsätze"
    subtitle="Bewerbungen, Zusagen und Verlauf"
    unread={summary.total_unread}
    onbell={() => goto('/community')}
  >
    {#snippet titleTrailing()}
      <a
        href="/calendar"
        class="flex items-center gap-2 rounded-xl bg-white/95 px-3.5 py-2 text-[13px] font-semibold text-secondary shadow-sm transition-transform active:scale-95"
      >
        <Icon name="calendar_today" size={16} />
        Kalender
      </a>
    {/snippet}
  </SageHeader>

  <div class="flex flex-col gap-md p-md">
    <div class="grid grid-cols-1 gap-sm sm:grid-cols-3">
      <div class="rounded-xl border border-outline-variant bg-surface p-md">
        <div
          class="flex items-center gap-2 text-[12px] font-semibold uppercase tracking-wide text-on-surface-variant"
        >
          <Icon name="hourglass_top" size={16} />
          Offen
        </div>
        <div class="mt-2 text-[26px] font-bold text-on-surface">{applications.length}</div>
        <p class="mt-1 text-[13px] text-on-surface-variant">Bewerbungen in Pruefung</p>
      </div>
      <div class="rounded-xl border border-outline-variant bg-surface p-md">
        <div
          class="flex items-center gap-2 text-[12px] font-semibold uppercase tracking-wide text-on-surface-variant"
        >
          <Icon name="event_available" size={16} />
          Zugesagt
        </div>
        <div class="mt-2 text-[26px] font-bold text-on-surface">{assignments.length}</div>
        <p class="mt-1 text-[13px] text-on-surface-variant">geplante Einsätze</p>
      </div>
      <div class="rounded-xl border border-outline-variant bg-surface p-md">
        <div
          class="flex items-center gap-2 text-[12px] font-semibold uppercase tracking-wide text-on-surface-variant"
        >
          <Icon name="today" size={16} />
          Nächster Termin
        </div>
        <div class="mt-2 line-clamp-1 text-[16px] font-bold text-on-surface">
          {nextAssignment?.offer?.starts_at
            ? formatDate(nextAssignment.offer.starts_at)
            : 'Keiner geplant'}
        </div>
        <p class="mt-1 line-clamp-1 text-[13px] text-on-surface-variant">
          {nextAssignment ? title(nextAssignment) : 'Bewirb dich auf passende Angebote.'}
        </p>
      </div>
    </div>

    {#if assignmentReminders.length > 0}
      <section class="rounded-xl border border-outline-variant bg-surface p-md">
        <header class="flex flex-wrap items-start justify-between gap-sm">
          <div>
            <div
              class="flex items-center gap-2 text-[12px] font-semibold uppercase tracking-wide text-on-surface-variant"
            >
              <Icon name="notifications_active" size={16} />
              Einsatz-Reminder
            </div>
            <h2 class="mt-1 text-[18px] font-bold text-on-surface">Naechste Erinnerungen</h2>
          </div>
          <Button
            variant="text"
            size="sm"
            leadingIcon="calendar_today"
            onclick={() => goto('/calendar')}
          >
            Kalender
          </Button>
        </header>
        <div class="mt-4 grid grid-cols-1 gap-xs sm:grid-cols-2">
          {#each assignmentReminders as reminder (reminder.id)}
            <div class="rounded-lg bg-surface-container-low p-sm">
              <div class="flex items-start justify-between gap-sm">
                <div class="min-w-0">
                  <p class="line-clamp-1 text-[13px] font-bold text-on-surface">
                    {reminder.offerTitle}
                  </p>
                  <p class="mt-1 text-[12px] text-on-surface-variant">
                    {reminder.label} · {formatDateTime(reminder.sentAt ?? reminder.scheduledAt)}
                  </p>
                </div>
                <span
                  class="shrink-0 rounded-full px-2 py-1 text-[11px] font-semibold {reminderStateClass(
                    reminder.state,
                  )}"
                >
                  {REMINDER_STATE_LABEL[reminder.state]}
                </span>
              </div>
              <p class="mt-2 line-clamp-2 text-[12px] leading-relaxed text-on-surface-variant">
                {reminder.detail}
              </p>
            </div>
          {/each}
        </div>
      </section>
    {/if}

    <Tabs items={tabs} bind:value={activeTab} variant="segmented" class="self-start" />

    {#if errorMessage}
      <Alert tone="error" title="Laden fehlgeschlagen">{errorMessage}</Alert>
    {/if}

    {#if loading}
      <div class="flex justify-center py-lg"><LoadingSpinner /></div>
    {:else if visibleRows.length === 0}
      <EmptyState
        icon={activeTab === 'assignments'
          ? 'event_busy'
          : activeTab === 'history'
            ? 'history'
            : 'how_to_reg'}
        title={activeTab === 'assignments'
          ? 'Noch keine zugesagten Einsätze'
          : activeTab === 'history'
            ? 'Noch kein Verlauf'
            : 'Keine offenen Bewerbungen'}
        description={activeTab === 'applications'
          ? 'Sobald du dich bewirbst, findest du den Status hier.'
          : 'Neue Aktivitäten erscheinen automatisch in dieser Übersicht.'}
      >
        {#snippet action()}
          <Button onclick={() => goto('/discover')} leadingIcon="search">Angebote entdecken</Button>
        {/snippet}
      </EmptyState>
    {:else}
      <div class="grid grid-cols-1 gap-sm lg:grid-cols-2">
        {#each visibleRows as row (row.id)}
          {@const rowTimeline = timeline(row)}
          <article
            class="flex min-h-[260px] flex-col rounded-xl border border-outline-variant bg-surface p-md"
          >
            <header class="flex items-start justify-between gap-sm">
              <div class="min-w-0">
                <div class="mb-2 flex flex-wrap items-center gap-2">
                  <Badge status={row.status}>{APPLICATION_STATUS_LABEL[row.status]}</Badge>
                  {#if row.offer}
                    <Badge status={row.offer.status}>{OFFER_STATUS_LABEL[row.offer.status]}</Badge>
                  {/if}
                </div>
                <h2 class="line-clamp-2 text-[18px] font-bold leading-tight text-on-surface">
                  {title(row)}
                </h2>
                <p class="mt-1 line-clamp-1 text-[13px] font-semibold text-on-surface-variant">
                  {organizationName(row)}
                </p>
              </div>
              {#if row.offer?.organization?.is_verified}
                <Icon name="verified" filled size={20} class="shrink-0 text-primary" />
              {/if}
            </header>

            <div class="mt-4 flex flex-col gap-2 text-[13px] text-on-surface-variant">
              <span class="inline-flex items-start gap-2">
                <Icon name="schedule" size={16} class="mt-0.5 shrink-0" />
                <span>{schedule(row)}</span>
              </span>
              <span class="inline-flex items-center gap-2">
                <Icon name={row.offer?.is_remote ? 'language' : 'location_on'} size={16} />
                {location(row)}
              </span>
              <span class="inline-flex items-center gap-2">
                <Icon name="send" size={16} />
                {submittedLine(row)}
              </span>
            </div>

            {#if row.motivation_text || row.helper_message}
              <div
                class="mt-4 rounded-lg bg-surface-container-low p-sm text-[13px] leading-relaxed text-on-surface"
              >
                {row.motivation_text ?? row.helper_message}
              </div>
            {/if}

            <div class="mt-4 border-l-2 border-outline-variant pl-sm">
              <p class="text-[13px] font-semibold text-on-surface">{statusHint(row)}</p>
              {#if statusDate(row)}
                <p class="mt-0.5 text-[12px] text-on-surface-variant">Stand: {statusDate(row)}</p>
              {/if}
            </div>

            <div
              class="mt-4 rounded-lg border border-outline-variant bg-surface-container-low p-sm"
            >
              <div
                class="flex items-center gap-2 text-[12px] font-semibold uppercase tracking-wide text-on-surface-variant"
              >
                <Icon name="timeline" size={16} />
                Timeline
              </div>
              <ol class="mt-3 flex flex-col gap-3">
                {#each rowTimeline as item (item.id)}
                  <li class="grid grid-cols-[22px_1fr] gap-2">
                    <span
                      class="mt-0.5 flex h-[22px] w-[22px] items-center justify-center rounded-full {timelineToneClass(
                        item.tone,
                      )}"
                    >
                      <Icon name={item.icon} size={13} />
                    </span>
                    <div class="min-w-0">
                      <div class="flex flex-wrap items-baseline justify-between gap-1">
                        <p class="text-[13px] font-semibold text-on-surface">{item.label}</p>
                        <p class="text-[11px] text-on-surface-variant">
                          {item.future ? 'Geplant' : formatRelative(item.at)}
                        </p>
                      </div>
                      <p
                        class="mt-0.5 line-clamp-2 text-[12px] leading-relaxed text-on-surface-variant"
                      >
                        {item.detail}
                      </p>
                      <p class="mt-0.5 text-[11px] text-on-surface-variant">
                        {formatDateTime(item.at)}
                      </p>
                    </div>
                  </li>
                {/each}
              </ol>
            </div>

            <div class="mt-auto flex flex-wrap justify-end gap-xs pt-md">
              {#if row.offer}
                <Button
                  variant="text"
                  size="sm"
                  leadingIcon="open_in_new"
                  onclick={() => goto(`/offers/${row.offer!.id}`)}
                >
                  Angebot
                </Button>
              {/if}
              <Button
                variant="outlined"
                size="sm"
                leadingIcon="chat"
                loading={busyIds.has(row.id)}
                onclick={() => openChat(row)}
              >
                Chat
              </Button>
              {#if WITHDRAWABLE_STATUSES.has(row.status)}
                <Button
                  variant="danger"
                  size="sm"
                  leadingIcon="undo"
                  loading={busyIds.has(row.id)}
                  onclick={() => {
                    selectedForWithdraw = row;
                    withdrawDialogOpen = true;
                  }}
                >
                  Zurückziehen
                </Button>
              {/if}
            </div>
          </article>
        {/each}
      </div>
    {/if}
  </div>
</section>

<ConfirmDialog
  bind:open={withdrawDialogOpen}
  title="Bewerbung zurückziehen?"
  message={selectedForWithdraw
    ? `Du ziehst deine Bewerbung fuer "${title(selectedForWithdraw)}" zurueck. Die Organisation sieht den neuen Status.`
    : ''}
  confirmLabel="Zurückziehen"
  tone="danger"
  onconfirm={confirmWithdraw}
  oncancel={() => {
    selectedForWithdraw = null;
    withdrawDialogOpen = false;
  }}
/>
