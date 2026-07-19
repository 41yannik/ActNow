import {
  applications,
  conversations,
  helperDocuments,
  helperProfiles,
  messages,
  notifications,
  offers,
  organizationProfiles,
  profiles,
  savedOffers,
} from './fixtures';
import type {
  ApplicationRow,
  ApplicationStatus,
  ApplicationWithOffer,
  CommunityConversationRow,
  CommunitySummary,
  ConversationRow,
  HelperDocumentRow,
  HelperProfileRow,
  NotificationRow,
  OfferRow,
  OfferStatus,
  OrganizationProfileRow,
  ProfileRow,
  SavedOfferWithOffer,
  SearchOfferResult,
  UUID,
} from '$lib/types/database';

export interface SearchOffersInput {
  location?: string | null;
  available_from?: string | null;
  available_to?: string | null;
  offer_type?: OfferRow['offer_type'] | null;
  tags?: string[] | null;
  limit?: number;
  offset?: number;
}

export interface OrgDashboardMetrics {
  open_offers: number;
  new_applications: number;
  upcoming_engagements: number;
  unread_messages: number;
}

function clone<T>(value: T): T {
  return structuredClone(value);
}

function profileById(id: UUID): ProfileRow | undefined {
  return profiles.find((row) => row.id === id);
}

function offerById(id: UUID): OfferRow | undefined {
  return offers.find((row) => row.id === id);
}

function orgDetails(id: UUID): OrganizationProfileRow | undefined {
  return organizationProfiles.find((row) => row.profile_id === id);
}

function helperDetails(id: UUID): HelperProfileRow | undefined {
  return helperProfiles.find((row) => row.profile_id === id);
}

export async function searchOffers(input: SearchOffersInput = {}): Promise<SearchOfferResult[]> {
  const location = input.location?.trim().toLocaleLowerCase('de') ?? '';
  const tags = input.tags?.map((tag) => tag.toLocaleLowerCase('de')) ?? [];
  const offset = input.offset ?? 0;
  const limit = input.limit ?? 20;

  const rows = offers
    .filter((row) => row.status === 'published')
    .filter((row) => !input.offer_type || row.offer_type === input.offer_type)
    .filter(
      (row) =>
        !location ||
        row.is_remote ||
        row.city?.toLocaleLowerCase('de').includes(location) ||
        row.location_name?.toLocaleLowerCase('de').includes(location),
    )
    .filter(
      (row) =>
        tags.length === 0 ||
        tags.every((tag) => row.skills_required.some((skill) => skill.toLowerCase() === tag)),
    )
    .filter(
      (row) => !input.available_from || !row.starts_at || row.starts_at >= input.available_from,
    )
    .filter((row) => !input.available_to || !row.starts_at || row.starts_at <= input.available_to)
    .sort((a, b) => (a.starts_at ?? '9999').localeCompare(b.starts_at ?? '9999'))
    .slice(offset, offset + limit)
    .map((row) => {
      const organization = profileById(row.organization_profile_id);
      return {
        id: row.id,
        organization_profile_id: row.organization_profile_id,
        title: row.title,
        description: row.description,
        offer_type: row.offer_type,
        status: row.status,
        category: row.category,
        skills_required: [...row.skills_required],
        city: row.city,
        is_remote: row.is_remote,
        starts_at: row.starts_at,
        ends_at: row.ends_at,
        application_deadline: row.application_deadline,
        published_at: row.published_at,
        organization_display_name: organization?.display_name ?? 'Demo-Organisation',
        organization_avatar_url: organization?.avatar_url ?? null,
        organization_average_rating: organization?.average_rating ?? null,
        organization_rating_count: organization?.rating_count ?? null,
        has_applied: false,
      } satisfies SearchOfferResult;
    });

  return clone(rows);
}

export async function getOffer(id: UUID): Promise<OfferRow | null> {
  return clone(offerById(id) ?? null);
}

export async function getOfferWithOrg(id: UUID) {
  const row = offerById(id);
  if (!row) return null;
  const organization = profileById(row.organization_profile_id);
  const details = orgDetails(row.organization_profile_id);
  return clone({
    ...row,
    organization: organization
      ? {
          organization_type: details?.organization_type ?? 'other',
          is_verified: details?.is_verified ?? true,
          profile: {
            id: organization.id,
            display_name: organization.display_name,
            slug: organization.slug,
            avatar_url: organization.avatar_url,
            average_rating: organization.average_rating,
            rating_count: organization.rating_count,
          },
        }
      : null,
  });
}

export async function listOrgOffers(
  organizationProfileId: UUID,
  status?: OfferStatus,
): Promise<OfferRow[]> {
  return clone(
    offers
      .filter(
        (row) =>
          row.organization_profile_id === organizationProfileId &&
          (!status || row.status === status),
      )
      .sort((a, b) => b.created_at.localeCompare(a.created_at)),
  );
}

export async function listApplicationsForOffer(
  offerId: UUID,
  status?: ApplicationStatus,
): Promise<ApplicationRow[]> {
  return clone(
    applications
      .filter((row) => row.offer_id === offerId && (!status || row.status === status))
      .sort((a, b) => b.submitted_at.localeCompare(a.submitted_at)),
  );
}

export async function listApplicationsForHelper(
  helperProfileId: UUID,
  status?: ApplicationStatus | ApplicationStatus[],
): Promise<ApplicationWithOffer[]> {
  const acceptedStatuses = Array.isArray(status) ? status : status ? [status] : null;
  const rows = applications
    .filter(
      (application) =>
        application.helper_profile_id === helperProfileId &&
        (!acceptedStatuses || acceptedStatuses.includes(application.status)),
    )
    .sort((a, b) => b.submitted_at.localeCompare(a.submitted_at))
    .map((application) => {
      const row = offerById(application.offer_id);
      const organization = row ? profileById(row.organization_profile_id) : undefined;
      const details = row ? orgDetails(row.organization_profile_id) : undefined;
      return {
        ...application,
        offer:
          row && organization
            ? {
                ...row,
                organization: {
                  organization_type: details?.organization_type ?? 'other',
                  is_verified: details?.is_verified ?? true,
                  profile: {
                    id: organization.id,
                    display_name: organization.display_name,
                    slug: organization.slug,
                    avatar_url: organization.avatar_url,
                    average_rating: organization.average_rating,
                    rating_count: organization.rating_count,
                  },
                },
              }
            : null,
      } satisfies ApplicationWithOffer;
    });
  return clone(rows);
}

export async function getProfile(profileId: UUID): Promise<ProfileRow | null> {
  return clone(profileById(profileId) ?? null);
}

export async function getProfiles(profileIds: UUID[]): Promise<ProfileRow[]> {
  const ids = new Set(profileIds);
  return clone(profiles.filter((row) => ids.has(row.id)));
}

export async function getHelperProfile(profileId: UUID): Promise<HelperProfileRow | null> {
  return clone(helperDetails(profileId) ?? null);
}

export async function getHelperProfiles(profileIds: UUID[]): Promise<HelperProfileRow[]> {
  const ids = new Set(profileIds);
  return clone(helperProfiles.filter((row) => ids.has(row.profile_id)));
}

export async function getOrganizationProfile(
  profileId: UUID,
): Promise<OrganizationProfileRow | null> {
  return clone(orgDetails(profileId) ?? null);
}

export async function getPublicProfileBySlug(slug: string): Promise<ProfileRow | null> {
  return clone(profiles.find((row) => row.slug === slug) ?? null);
}

export async function listHelperDocuments(helperProfileId: UUID): Promise<HelperDocumentRow[]> {
  return clone(
    helperDocuments
      .filter((row) => row.helper_profile_id === helperProfileId && row.status === 'active')
      .sort((a, b) => b.created_at.localeCompare(a.created_at)),
  );
}

export async function listSavedOffers(helperProfileId: UUID): Promise<SavedOfferWithOffer[]> {
  return clone(
    savedOffers
      .filter((row) => row.helper_profile_id === helperProfileId)
      .sort((a, b) => b.created_at.localeCompare(a.created_at))
      .map((row) => ({ ...row, offer: offerById(row.offer_id) ?? null })),
  );
}

export async function listSavedOfferIds(helperProfileId: UUID): Promise<Set<UUID>> {
  return new Set(
    savedOffers
      .filter((row) => row.helper_profile_id === helperProfileId)
      .map((row) => row.offer_id),
  );
}

export async function getConversation(id: UUID): Promise<ConversationRow | null> {
  return clone(conversations.find((row) => row.id === id) ?? null);
}

export async function getConversationForApplication(
  applicationId: UUID,
): Promise<ConversationRow | null> {
  return clone(conversations.find((row) => row.application_id === applicationId) ?? null);
}

export async function listMessages(conversationId: UUID, limit = 100) {
  return clone(
    messages
      .filter((row) => row.conversation_id === conversationId)
      .sort((a, b) => a.created_at.localeCompare(b.created_at))
      .slice(0, limit),
  );
}

export async function listCommunityConversations(
  profileId: UUID,
  limit = 50,
  offset = 0,
): Promise<CommunityConversationRow[]> {
  const rows = conversations
    .filter(
      (conversation) =>
        conversation.helper_profile_id === profileId ||
        conversation.organization_profile_id === profileId,
    )
    .sort((a, b) => (b.last_message_at ?? '').localeCompare(a.last_message_at ?? ''))
    .slice(offset, offset + limit)
    .map((conversation) => {
      const counterpartId =
        conversation.helper_profile_id === profileId
          ? conversation.organization_profile_id
          : conversation.helper_profile_id;
      const counterpart = profileById(counterpartId);
      const rowOffer = offerById(conversation.offer_id);
      const thread = messages
        .filter((message) => message.conversation_id === conversation.id)
        .sort((a, b) => b.created_at.localeCompare(a.created_at));
      const latest = thread[0];
      return {
        conversation_id: conversation.id,
        application_id: conversation.application_id,
        offer_id: conversation.offer_id,
        offer_title: rowOffer?.title ?? 'Demo-Angebot',
        helper_profile_id: conversation.helper_profile_id,
        organization_profile_id: conversation.organization_profile_id,
        counterparty_profile_id: counterpartId,
        counterparty_display_name: counterpart?.display_name ?? 'Demo-Profil',
        counterparty_avatar_url: counterpart?.avatar_url ?? null,
        last_message_body: latest?.body ?? null,
        last_message_sender_profile_id: latest?.sender_profile_id ?? null,
        last_message_at: latest?.created_at ?? conversation.last_message_at,
        unread_count: thread.filter(
          (message) => message.sender_profile_id !== profileId && message.read_at === null,
        ).length,
        created_at: conversation.created_at,
        updated_at: conversation.updated_at,
      } satisfies CommunityConversationRow;
    });
  return clone(rows);
}

export async function listNotifications(profileId: UUID, limit = 30): Promise<NotificationRow[]> {
  return clone(
    notifications
      .filter((row) => row.recipient_profile_id === profileId)
      .sort((a, b) => b.created_at.localeCompare(a.created_at))
      .slice(0, limit),
  );
}

export async function listApplicationNotifications(
  applicationIds: UUID[],
  limit = 100,
): Promise<NotificationRow[]> {
  const ids = new Set(applicationIds);
  return clone(
    notifications
      .filter(
        (row) => row.entity_type === 'application' && !!row.entity_id && ids.has(row.entity_id),
      )
      .sort((a, b) => b.created_at.localeCompare(a.created_at))
      .slice(0, limit),
  );
}

export async function getCommunitySummary(profileId: UUID): Promise<CommunitySummary> {
  const unreadMessages = messages.filter((message) => {
    const conversation = conversations.find((row) => row.id === message.conversation_id);
    return (
      conversation &&
      (conversation.helper_profile_id === profileId ||
        conversation.organization_profile_id === profileId) &&
      message.sender_profile_id !== profileId &&
      message.read_at === null
    );
  }).length;
  const unreadNotifications = notifications.filter(
    (row) => row.recipient_profile_id === profileId && row.read_at === null,
  ).length;
  return {
    unread_messages: unreadMessages,
    unread_notifications: unreadNotifications,
    total_unread: unreadMessages + unreadNotifications,
  };
}

export async function getOrgDashboardMetrics(
  organizationProfileId: UUID,
): Promise<OrgDashboardMetrics> {
  const orgOfferIds = new Set(
    offers
      .filter((row) => row.organization_profile_id === organizationProfileId)
      .map((row) => row.id),
  );
  const orgConversations = new Set(
    conversations
      .filter((row) => row.organization_profile_id === organizationProfileId)
      .map((row) => row.id),
  );
  return {
    open_offers: offers.filter(
      (row) =>
        row.organization_profile_id === organizationProfileId &&
        ['published', 'paused'].includes(row.status),
    ).length,
    new_applications: applications.filter(
      (row) => orgOfferIds.has(row.offer_id) && row.status === 'submitted',
    ).length,
    upcoming_engagements: applications.filter((row) => {
      const rowOffer = offerById(row.offer_id);
      return (
        orgOfferIds.has(row.offer_id) &&
        row.status === 'accepted' &&
        !!rowOffer?.starts_at &&
        rowOffer.starts_at >= new Date().toISOString()
      );
    }).length,
    unread_messages: messages.filter(
      (row) =>
        orgConversations.has(row.conversation_id) &&
        row.sender_profile_id !== organizationProfileId &&
        row.read_at === null,
    ).length,
  };
}

// Explicit public read API. Object.freeze prevents accidental replacement of
// repository methods and makes the lack of write/RPC operations visible.
export const DemoRepository = Object.freeze({
  searchOffers,
  getOffer,
  getOfferWithOrg,
  listOrgOffers,
  listApplicationsForOffer,
  listApplicationsForHelper,
  getProfile,
  getProfiles,
  getHelperProfile,
  getHelperProfiles,
  getOrganizationProfile,
  getPublicProfileBySlug,
  listHelperDocuments,
  listSavedOffers,
  listSavedOfferIds,
  getConversation,
  getConversationForApplication,
  listMessages,
  listCommunityConversations,
  listNotifications,
  listApplicationNotifications,
  getCommunitySummary,
  getOrgDashboardMetrics,
});
