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
        primary: '#476500',
        'surface-container-highest': '#e5e2db',
        'tertiary-fixed': '#d7e8c6',
        outline: '#747967',
        'on-primary-fixed-variant': '#364e00',
        'on-primary-fixed': '#131f00',
        'on-tertiary': '#ffffff',
        'on-secondary-fixed-variant': '#2c4c4c',
        'on-tertiary-container': '#f9ffed',
        'inverse-surface': '#31312c',
        'error-container': '#ffdad6',
        'on-secondary-container': '#4a6a6a',
        'surface-container': '#f0eee7',
        'primary-container': '#5d7f13',
        'on-secondary-fixed': '#002020',
        'surface-bright': '#fcf9f2',
        background: '#fcf9f2',
        'secondary-fixed-dim': '#abcdcd',
        'on-error-container': '#93000a',
        'on-secondary': '#ffffff',
        'primary-fixed-dim': '#add461',
        'surface-dim': '#dcdad3',
        'surface-container-high': '#ebe8e1',
        'on-primary-container': '#faffe7',
        'on-surface': '#1c1c18',
        'on-surface-variant': '#444939',
        secondary: '#446464',
        'on-primary': '#ffffff',
        'surface-variant': '#e5e2db',
        'surface-tint': '#496800',
        'surface-container-lowest': '#ffffff',
        'inverse-primary': '#add461',
        'outline-variant': '#c4c9b4',
        error: '#ba1a1a',
        'tertiary-fixed-dim': '#bcccab',
        'on-tertiary-fixed': '#131f09',
        'secondary-container': '#c6e9e9',
        tertiary: '#526045',
        'on-tertiary-fixed-variant': '#3d4b32',
        surface: '#fcf9f2',
        'on-background': '#1c1c18',
        'surface-container-low': '#f6f3ec',
        'inverse-on-surface': '#f3f0ea',
        'tertiary-container': '#6a795d',
        'primary-fixed': '#c8f17a',
        'secondary-fixed': '#c6e9e9'
      },
      borderRadius: {
        DEFAULT: '0.25rem',
        lg: '0.5rem',
        xl: '0.75rem',
        full: '9999px'
      },
      spacing: {
        xs: '4px',
        base: '8px',
        sm: '12px',
        md: '24px',
        gutter: '24px',
        lg: '48px',
        xl: '80px',
        'container-max': '1280px'
      },
      fontFamily: {
        'h1-mobile': ['Montserrat', 'sans-serif'],
        'h2-mobile': ['Montserrat', 'sans-serif'],
        h1: ['Montserrat', 'sans-serif'],
        h2: ['Montserrat', 'sans-serif'],
        h3: ['Montserrat', 'sans-serif'],
        'body-md': ['"Atkinson Hyperlegible Next"', 'sans-serif'],
        'body-lg': ['"Atkinson Hyperlegible Next"', 'sans-serif'],
        'label-md': ['"Atkinson Hyperlegible Next"', 'sans-serif']
      },
      fontSize: {
        'h1-mobile': ['32px', { lineHeight: '1.2', fontWeight: '700' }],
        'h2-mobile': ['24px', { lineHeight: '1.3', fontWeight: '600' }],
        h1: ['40px', { lineHeight: '1.2', letterSpacing: '-0.02em', fontWeight: '700' }],
        h2: ['32px', { lineHeight: '1.3', fontWeight: '600' }],
        h3: ['24px', { lineHeight: '1.4', fontWeight: '600' }],
        'body-lg': ['18px', { lineHeight: '1.6', fontWeight: '400' }],
        'body-md': ['16px', { lineHeight: '1.6', fontWeight: '400' }],
        'label-md': ['14px', { lineHeight: '1.2', letterSpacing: '0.01em', fontWeight: '600' }]
      },
      maxWidth: {
        'container-max': '1280px'
      }
    }
  },
  plugins: [forms, containerQueries]
};
