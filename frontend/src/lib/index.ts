// Re-exports for the shared component library.
// Keep this file small — only export shared atoms here.
// Feature-specific components live under src/lib/features/<feature>/components/.

// Foundations
export { default as Icon } from './components/ui/Icon.svelte';

// Primitives (atoms)
export { default as Button } from './components/ui/Button.svelte';
export { default as IconButton } from './components/ui/IconButton.svelte';
export { default as Chip } from './components/ui/Chip.svelte';
export { default as Avatar } from './components/ui/Avatar.svelte';
export { default as OrgLogo } from './components/ui/OrgLogo.svelte';
export { default as RatingStars } from './components/ui/RatingStars.svelte';
export { default as Badge } from './components/ui/Badge.svelte';
export { default as Tag } from './components/ui/Tag.svelte';

// Feedback
export { default as EmptyState } from './components/ui/EmptyState.svelte';
export { default as LoadingSpinner } from './components/ui/LoadingSpinner.svelte';
export { default as Alert } from './components/ui/Alert.svelte';
export { default as Toast } from './components/ui/Toast.svelte';
export { default as ToastHost } from './components/ui/ToastHost.svelte';
export { default as Modal } from './components/ui/Modal.svelte';
export { default as ConfirmDialog } from './components/ui/ConfirmDialog.svelte';
export { default as Skeleton } from './components/ui/Skeleton.svelte';
export { default as Tabs } from './components/ui/Tabs.svelte';
export { default as Dropdown } from './components/ui/Dropdown.svelte';
export { default as DropdownItem } from './components/ui/DropdownItem.svelte';

// Forms
export { default as TextField } from './components/forms/TextField.svelte';
export { default as TextArea } from './components/forms/TextArea.svelte';
export { default as Select } from './components/forms/Select.svelte';
export { default as Checkbox } from './components/forms/Checkbox.svelte';
export { default as Radio } from './components/forms/Radio.svelte';
export { default as CheckboxCard } from './components/forms/CheckboxCard.svelte';
export { default as RadioCard } from './components/forms/RadioCard.svelte';
export { default as FormSection } from './components/forms/FormSection.svelte';
export { default as PasswordInput } from './components/forms/PasswordInput.svelte';
export { default as DatePicker } from './components/forms/DatePicker.svelte';
export { default as TimePicker } from './components/forms/TimePicker.svelte';
export { default as TagInput } from './components/forms/TagInput.svelte';
export { default as FileUploader } from './components/forms/FileUploader.svelte';

// Layout
export { default as TopNavBar } from './components/layout/TopNavBar.svelte';
export { default as BottomNavBar } from './components/layout/BottomNavBar.svelte';
export { default as SideNavBar } from './components/layout/SideNavBar.svelte';
export { default as PageHeader } from './components/layout/PageHeader.svelte';
export { default as AppShell } from './components/layout/AppShell.svelte';
export { default as Footer } from './components/layout/Footer.svelte';
export { default as MobileTopBar } from './components/layout/MobileTopBar.svelte';

// Offers / Swipe (key feature)
export { default as SwipeCard } from './features/offers/components/SwipeCard.svelte';
export { default as SwipeDeck } from './features/offers/components/SwipeDeck.svelte';
export { default as SwipeActionBar } from './features/offers/components/SwipeActionBar.svelte';
