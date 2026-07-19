// Presentation data contracts retained from the original database design.
// The static portfolio demo fills these shapes from local TypeScript fixtures.

export type UUID = string;
export type ISODateTime = string;
export type ISODate = string;

export type UserRole = 'helper' | 'organization' | 'admin';
export type ProfileStatus = 'active' | 'inactive' | 'suspended' | 'deleted';
export type OrganizationType =
  | 'club'
  | 'nonprofit'
  | 'initiative'
  | 'public_institution'
  | 'company'
  | 'private_person'
  | 'other';

export type OfferType = 'single_event' | 'recurring_event' | 'flexible_task' | 'digital_task';

export type OfferStatus =
  'draft' | 'published' | 'paused' | 'filled' | 'completed' | 'cancelled' | 'archived';

export type ApplicationStatus =
  | 'submitted'
  | 'shortlisted'
  | 'accepted'
  | 'rejected'
  | 'withdrawn'
  | 'cancelled'
  | 'completed'
  | 'no_show';

export type DocumentType =
  'criminal_record_certificate' | 'identity_document' | 'qualification' | 'certificate' | 'other';

export type DocumentStatus = 'active' | 'expired' | 'revoked' | 'deleted';
export type MessageStatus = 'sent' | 'read' | 'deleted';
export type RecurrenceFrequency = 'daily' | 'weekly' | 'monthly' | 'custom';

export interface ProfileRow {
  id: UUID;
  user_id: UUID;
  role: UserRole;
  status: ProfileStatus;
  display_name: string;
  slug: string;
  avatar_url: string | null;
  bio: string | null;
  city: string | null;
  postal_code: string | null;
  country_code: string;
  phone: string | null;
  website_url: string | null;
  average_rating: number;
  rating_count: number;
  created_at: ISODateTime;
  updated_at: ISODateTime;
}

export interface HelperProfileRow {
  profile_id: UUID;
  date_of_birth: ISODate | null;
  skills: string[];
  languages: string[];
  availability_note: string | null;
  has_drivers_license: boolean;
  has_car: boolean;
  emergency_contact_name: string | null;
  emergency_contact_phone: string | null;
  created_at: ISODateTime;
  updated_at: ISODateTime;
}

export interface OrganizationProfileRow {
  profile_id: UUID;
  organization_type: OrganizationType;
  legal_name: string | null;
  registration_number: string | null;
  tax_id: string | null;
  contact_person_name: string | null;
  contact_email: string | null;
  contact_phone: string | null;
  is_verified: boolean;
  verified_at: ISODateTime | null;
  created_at: ISODateTime;
  updated_at: ISODateTime;
}

export interface OfferRow {
  id: UUID;
  organization_profile_id: UUID;
  title: string;
  description: string;
  offer_type: OfferType;
  status: OfferStatus;
  category: string | null;
  skills_required: string[];
  min_age: number | null;
  max_helpers: number | null;
  accepted_helpers_count: number;
  location_name: string | null;
  street: string | null;
  postal_code: string | null;
  city: string | null;
  country_code: string;
  is_remote: boolean;
  starts_at: ISODateTime | null;
  ends_at: ISODateTime | null;
  application_deadline: ISODateTime | null;
  is_binding: boolean;
  requires_documents: boolean;
  published_at: ISODateTime | null;
  completed_at: ISODateTime | null;
  cancelled_at: ISODateTime | null;
  created_at: ISODateTime;
  updated_at: ISODateTime;
}

export interface ApplicationRow {
  id: UUID;
  offer_id: UUID;
  helper_profile_id: UUID;
  status: ApplicationStatus;
  motivation_text: string | null;
  organization_note: string | null;
  helper_message: string | null;
  submitted_at: ISODateTime;
  accepted_at: ISODateTime | null;
  rejected_at: ISODateTime | null;
  withdrawn_at: ISODateTime | null;
  completed_at: ISODateTime | null;
  created_at: ISODateTime;
  updated_at: ISODateTime;
}

export interface ApplicationOfferWithOrganization extends OfferRow {
  organization: {
    organization_type: OrganizationType;
    is_verified: boolean;
    profile: Pick<
      ProfileRow,
      'id' | 'display_name' | 'slug' | 'avatar_url' | 'average_rating' | 'rating_count'
    >;
  } | null;
}

export interface ApplicationWithOffer extends ApplicationRow {
  offer: ApplicationOfferWithOrganization | null;
}

export interface ConversationRow {
  id: UUID;
  application_id: UUID;
  offer_id: UUID;
  helper_profile_id: UUID;
  organization_profile_id: UUID;
  last_message_at: ISODateTime | null;
  created_at: ISODateTime;
  updated_at: ISODateTime;
}

export interface MessageRow {
  id: UUID;
  conversation_id: UUID;
  sender_profile_id: UUID;
  body: string;
  status: MessageStatus;
  read_at: ISODateTime | null;
  created_at: ISODateTime;
  updated_at: ISODateTime;
}

export interface NotificationRow {
  id: UUID;
  recipient_profile_id: UUID;
  type: string;
  title: string;
  body: string | null;
  entity_type: string | null;
  entity_id: UUID | null;
  read_at: ISODateTime | null;
  created_at: ISODateTime;
}

export interface HelperDocumentRow {
  id: UUID;
  helper_profile_id: UUID;
  document_type: DocumentType;
  status: DocumentStatus;
  title: string;
  description: string | null;
  storage_bucket: string;
  storage_path: string;
  mime_type: string;
  file_size_bytes: number;
  issued_at: ISODate | null;
  expires_at: ISODate | null;
  created_at: ISODateTime;
  updated_at: ISODateTime;
}

export interface SavedOfferRow {
  id: UUID;
  helper_profile_id: UUID;
  offer_id: UUID;
  created_at: ISODateTime;
}

export interface SavedOfferWithOffer extends SavedOfferRow {
  offer: OfferRow | null;
}

export interface CommunityConversationRow {
  conversation_id: UUID;
  application_id: UUID;
  offer_id: UUID;
  offer_title: string;
  helper_profile_id: UUID;
  organization_profile_id: UUID;
  counterparty_profile_id: UUID;
  counterparty_display_name: string;
  counterparty_avatar_url: string | null;
  last_message_body: string | null;
  last_message_sender_profile_id: UUID | null;
  last_message_at: ISODateTime | null;
  unread_count: number;
  created_at: ISODateTime;
  updated_at: ISODateTime;
}

export interface CommunitySummary {
  unread_messages: number;
  unread_notifications: number;
  total_unread: number;
}

// Result row of search_offers() RPC.
export interface SearchOfferResult {
  id: UUID;
  organization_profile_id: UUID;
  title: string;
  description: string;
  offer_type: OfferType;
  status: OfferStatus;
  category: string | null;
  skills_required: string[];
  city: string | null;
  is_remote: boolean;
  starts_at: ISODateTime | null;
  ends_at: ISODateTime | null;
  application_deadline: ISODateTime | null;
  published_at: ISODateTime | null;
  organization_display_name: string;
  organization_avatar_url: string | null;
  organization_average_rating: number | null;
  organization_rating_count: number | null;
  has_applied: boolean;
}
