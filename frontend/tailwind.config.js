/** @type {import('tailwindcss').Config} */
// ActNow design tokens — extracted from docs/*.html (Material 3-ish theme).
// Single source of truth: keep in sync with the mockups in /docs.
import forms from '@tailwindcss/forms';
import containerQueries from '@tailwindcss/container-queries';

export default {
  content: ['./src/**/*.{html,svelte,js,ts}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        'on-error': '#ffffff',
        primary: '#7E8F6B', // Dunkles Salbei (Primäraktionen)
        'primary-container': '#9DAD93', // Salbei (Header-Band)
        'on-primary': '#ffffff',
        'on-primary-container': '#ffffff',
        'on-primary-fixed': '#131f00',
        'on-primary-fixed-variant': '#364e00',
        'primary-fixed': '#c8f17a',
        'primary-fixed-dim': '#add461',
        'inverse-primary': '#add461',

        secondary: '#5F6E4D', // Olive (Akzent, stärkere Linien)
        'on-secondary': '#ffffff',
        'secondary-container': '#B7C2AE', // Helles Salbei
        'on-secondary-container': '#3F4837', // Oliven-Text
        'secondary-fixed': '#c6e9e9',
        'secondary-fixed-dim': '#abcdcd',
        'on-secondary-fixed': '#002020',
        'on-secondary-fixed-variant': '#2c4c4c',

        tertiary: '#E2945A', // SOS Orange (Warnfarbe der Vorlage)
        'on-tertiary': '#ffffff',
        'tertiary-container': '#FAF8F2',
        'on-tertiary-container': '#3F4837',
        'tertiary-fixed': '#B7C2AE',
        'tertiary-fixed-dim': '#bcccab',
        'on-tertiary-fixed': '#131f09',
        'on-tertiary-fixed-variant': '#3d4b32',

        background: '#F5F2EA', // Warmes Creme (Hintergrund)
        'on-background': '#1F2520', // Tintenschwarz (Fließtext)

        surface: '#FFFFFF', // Reinweiß für Karten & Oberflächen
        'on-surface': '#1F2520',
        'on-surface-variant': '#737872', // Muted/Faint Grau
        'surface-variant': '#FAF8F2',
        'surface-bright': '#FFFFFF',
        'surface-dim': '#FAF8F2',

        'surface-container-lowest': '#FFFFFF',
        'surface-container-low': '#FAF8F2', // Weiches Creme für schwebende Container
        'surface-container': '#FAF8F2',
        'surface-container-high': '#EFEBE0', // Haarlinie Soft-Hintergründe
        'surface-container-highest': '#E6E2D7',

        'inverse-surface': '#1F2520',
        'inverse-on-surface': '#F5F2EA',

        outline: '#E6E2D7', // Haarlinie-Rahmen (faint/hair)
        'outline-variant': '#EFEBE0', // Weichere Haarlinie (hairSoft)

        error: '#ba1a1a',
        'error-container': '#ffdad6',
        'on-error-container': '#93000a',

        'surface-tint': '#7E8F6B',
        'blue-dot': '#5B7AAE', // Blau für Kalender-Dots oder Socials
      },
      borderRadius: {
        DEFAULT: '0.25rem',
        lg: '0.5rem',
        xl: '0.75rem',
        full: '9999px',
        btn: '14px', // Ecken der Buttons in der Vorlage
        card: '22px', // Ecken der Swipe-Karten
        header: '28px', // Ecken des SageHeaders unten
      },
      spacing: {
        xs: '4px',
        base: '8px',
        sm: '12px',
        md: '24px',
        gutter: '24px',
        lg: '48px',
        xl: '80px',
        'container-max': '1280px',
      },
      fontFamily: {
        'h1-mobile': ['Inter', 'sans-serif'],
        'h2-mobile': ['Inter', 'sans-serif'],
        h1: ['Inter', 'sans-serif'],
        h2: ['Inter', 'sans-serif'],
        h3: ['Inter', 'sans-serif'],
        'body-md': ['Inter', 'sans-serif'],
        'body-lg': ['Inter', 'sans-serif'],
        'label-md': ['Inter', 'sans-serif'],
      },
      fontSize: {
        'h1-mobile': ['32px', { lineHeight: '1.2', fontWeight: '700' }],
        'h2-mobile': ['24px', { lineHeight: '1.3', fontWeight: '600' }],
        h1: ['40px', { lineHeight: '1.2', letterSpacing: '-0.02em', fontWeight: '700' }],
        h2: ['32px', { lineHeight: '1.3', fontWeight: '600' }],
        h3: ['24px', { lineHeight: '1.4', fontWeight: '600' }],
        'body-lg': ['18px', { lineHeight: '1.6', fontWeight: '400' }],
        'body-md': ['16px', { lineHeight: '1.6', fontWeight: '400' }],
        'label-md': ['14px', { lineHeight: '1.2', letterSpacing: '0.01em', fontWeight: '600' }],
      },
      maxWidth: {
        'container-max': '1280px',
      },
    },
  },
  plugins: [forms, containerQueries],
};
