// German status labels.
import type { ApplicationStatus, OfferStatus } from '$lib/types/database';

export const OFFER_STATUS_LABEL: Record<OfferStatus, string> = {
  draft: 'Entwurf',
  published: 'Veröffentlicht',
  paused: 'Pausiert',
  filled: 'Voll',
  completed: 'Abgeschlossen',
  cancelled: 'Abgesagt',
  archived: 'Archiviert'
};

export const APPLICATION_STATUS_LABEL: Record<ApplicationStatus, string> = {
  submitted: 'Eingereicht',
  shortlisted: 'In Vorauswahl',
  accepted: 'Zugesagt',
  rejected: 'Abgesagt',
  withdrawn: 'Zurückgezogen',
  cancelled: 'Storniert',
  completed: 'Abgeschlossen',
  no_show: 'Nicht erschienen'
};
