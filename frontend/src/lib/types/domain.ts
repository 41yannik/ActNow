// Domain (presentation-shaped) types. Database row types live in ./database.ts.
import type {
  OfferType,
  OfferStatus,
  SearchOfferResult
} from './database';

// Re-export the database enums so existing imports keep working.
export type {
  OfferType,
  OfferStatus,
  ApplicationStatus,
  UserRole,
  ProfileStatus
} from './database';

export interface Offer {
  id: string;
  title: string;
  description: string;
  offer_type: OfferType;
  status: OfferStatus;
  organization_id: string;
  organization_name: string;
  organization_slug?: string;
  organization_avatar_url?: string | null;
  organization_rating?: number | null;
  cover_image_url?: string | null;
  category?: string | null;
  city?: string | null;
  is_remote: boolean;
  starts_at?: string | null;
  ends_at?: string | null;
  schedule_text?: string | null;
  helpers_needed: number;
  accepted_helpers_count: number;
  requirements?: string[];
  tags?: string[];
}

export interface OrganizationSummary {
  id: string;
  slug: string;
  display_name: string;
  avatar_url?: string | null;
  city?: string | null;
  average_rating: number;
  rating_count: number;
}

export interface HelperSummary {
  id: string;
  slug: string;
  display_name: string;
  avatar_url?: string | null;
  city?: string | null;
  average_rating: number;
  rating_count: number;
}

/**
 * Map a `search_offers` RPC row to the presentation `Offer` shape used by
 * SwipeCard / OfferPreviewCard. Keeps callers free of field renames.
 */
export function offerFromSearchResult(row: SearchOfferResult): Offer {
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    offer_type: row.offer_type,
    status: row.status,
    organization_id: row.organization_profile_id,
    organization_name: row.organization_display_name,
    organization_avatar_url: row.organization_avatar_url,
    organization_rating: row.organization_average_rating ?? null,
    cover_image_url: null,
    category: row.category,
    city: row.city,
    is_remote: row.is_remote,
    starts_at: row.starts_at,
    ends_at: row.ends_at,
    helpers_needed: 0,
    accepted_helpers_count: 0,
    requirements: [],
    tags: row.skills_required
  };
}
