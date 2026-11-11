// Pure helpers for the GA4 realtime card. No Google client import here, so the
// parsing rules stay unit-testable without credentials.

/// Converts a GA4 metric value (always a string) to a finite number.
function metric(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

/// Normalises a `runRealtimeReport` response into the shape the dashboard
/// renders. Totals usually carry `activeUsers` and `eventCount`; event rows
/// carry `eventCount` only (GA4 rejects `activeUsers` together with the
/// `eventName` dimension). When totals are missing the rows are summed (an
/// approximation, since one active user can trigger several events).
export function parseRealtimeReport(report) {
  const rows = (report?.rows ?? [])
    .map((row) => {
      const values = row?.metricValues ?? [];
      const singleMetric = values.length < 2;
      return {
        event: row?.dimensionValues?.[0]?.value ?? '',
        users: singleMetric ? null : metric(values[0]?.value),
        events: metric((singleMetric ? values[0] : values[1])?.value),
      };
    })
    .filter((row) => row.event);

  const totals = report?.totals?.[0]?.metricValues;
  if (Array.isArray(totals) && totals.length >= 2) {
    return {
      activeUsers: metric(totals[0]?.value),
      totalEvents: metric(totals[1]?.value),
      rows,
    };
  }

  return {
    activeUsers: rows.reduce((sum, row) => sum + (row.users ?? 0), 0),
    totalEvents: rows.reduce((sum, row) => sum + row.events, 0),
    rows,
  };
}

/// Short quota line for the dashboard (remaining realtime tokens for this
/// project/property/hour), or null when GA4 did not return a quota object.
export function quotaRemaining(quota) {
  const remaining = quota?.tokensPerProjectPerHour?.remaining;
  const parsed = Number(remaining);
  return Number.isFinite(parsed) ? parsed : null;
}
