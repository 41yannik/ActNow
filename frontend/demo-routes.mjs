const offerIds = [
  'offer-sommerfest',
  'offer-kindertraining',
  'offer-tafel',
  'offer-cleanup',
  'offer-lesepaten',
  'offer-kuechenteam',
  'offer-gartenaktion',
  'offer-webseite',
  'offer-seniorencafe',
  'offer-nachhilfe-draft',
];

const conversationIds = [
  'conversation-anna-sommerfest',
  'conversation-bernd-sommerfest',
  'conversation-anna-training',
  'conversation-anna-tafel',
  'conversation-anna-kueche',
];

/**
 * Paths that GitHub Pages must serve as real HTML documents. Unknown IDs still
 * use the SPA fallback and are handled by the app's friendly not-found views.
 */
export const staticDemoRoutes = [
  '/',
  '/agb',
  '/applications',
  '/calendar',
  '/community',
  '/dashboard',
  '/datenschutz',
  '/discover',
  '/favorites',
  '/impressum',
  '/login',
  '/messages',
  '/offers',
  '/offers/new',
  '/profile',
  '/register',
  '/rewards',
  '/showcase',
  ...offerIds.map((id) => `/offers/${id}`),
  ...offerIds.map((id) => `/offers/${id}/applications`),
  ...conversationIds.map((id) => `/messages/${id}`),
];
