import { z } from 'zod';

export const offerSchema = z
  .object({
    title: z.string().min(5, 'Mindestens 5 Zeichen.').max(160),
    description: z.string().min(20, 'Mindestens 20 Zeichen.').max(5000),
    offer_type: z.enum(['single_event', 'recurring_event', 'flexible_task', 'digital_task']),
    category: z.string().max(80).optional().nullable(),
    skills_required: z.array(z.string()).default([]),
    min_age: z.number().int().min(0).max(120).optional().nullable(),
    max_helpers: z.number().int().positive().optional().nullable(),
    location_name: z.string().max(160).optional().nullable(),
    city: z.string().max(120).optional().nullable(),
    postal_code: z.string().max(20).optional().nullable(),
    street: z.string().max(160).optional().nullable(),
    is_remote: z.boolean().default(false),
    starts_at: z.string().datetime().optional().nullable(),
    ends_at: z.string().datetime().optional().nullable(),
    application_deadline: z.string().datetime().optional().nullable(),
    requires_documents: z.boolean().default(false),
  })
  .refine((d) => d.is_remote || (d.city && d.city.length > 0), {
    path: ['city'],
    message: 'Ort erforderlich, falls nicht remote.',
  })
  .refine(
    (d) => d.starts_at == null || d.ends_at == null || new Date(d.ends_at) > new Date(d.starts_at),
    { path: ['ends_at'], message: 'Endzeit muss nach Startzeit liegen.' },
  );

export type OfferInput = z.infer<typeof offerSchema>;
