export function formatTime(iso) {
  if (!iso) return 'time unknown';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return 'time unknown';
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date);
}

export function displayName(user) {
  return user?.name || user?.email || user?.uid || 'Unknown user';
}
