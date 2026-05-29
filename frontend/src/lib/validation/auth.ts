// Shared zod schemas. Used by client forms and server actions.
import { z } from 'zod';

export const email = z.string().email('Bitte eine gültige E-Mail eingeben.');
export const password = z
  .string()
  .min(8, 'Mindestens 8 Zeichen.')
  .max(72, 'Maximal 72 Zeichen.');

export const registerSchema = z
  .object({
    role: z.enum(['helper', 'organization']),
    display_name: z.string().min(2, 'Mindestens 2 Zeichen.').max(120),
    organization_name: z.string().max(160).optional(),
    email,
    password,
    accept_terms: z.literal(true, {
      message: 'Bitte den Nutzungsbedingungen zustimmen.'
    })
  })
  .refine(
    (data) =>
      data.role !== 'organization' ||
      (data.organization_name?.trim().length ?? 0) >= 2,
    {
      path: ['organization_name'],
      message: 'Organisationsname erforderlich.'
    }
  );

export type RegisterInput = z.infer<typeof registerSchema>;

export const loginSchema = z.object({
  email,
  password: z.string().min(1, 'Bitte Passwort eingeben.')
});
export type LoginInput = z.infer<typeof loginSchema>;
