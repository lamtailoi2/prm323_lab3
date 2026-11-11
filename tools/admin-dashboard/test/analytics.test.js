import assert from 'node:assert/strict';
import test from 'node:test';

import { parseRealtimeReport, quotaRemaining } from '../lib/analytics.js';

test('parseRealtimeReport uses totals and keeps the event rows', () => {
  const report = {
    totals: [
      {
        metricValues: [{ value: '12' }, { value: '34' }],
      },
    ],
    rows: [
      {
        dimensionValues: [{ value: 'screen_view' }],
        metricValues: [{ value: '10' }, { value: '20' }],
      },
      {
        dimensionValues: [{ value: 'search' }],
        metricValues: [{ value: '2' }, { value: '14' }],
      },
    ],
  };

  assert.deepEqual(parseRealtimeReport(report), {
    activeUsers: 12,
    totalEvents: 34,
    rows: [
      { event: 'screen_view', users: 10, events: 20 },
      { event: 'search', users: 2, events: 14 },
    ],
  });
});

test('parseRealtimeReport sums rows when totals are missing', () => {
  const report = {
    rows: [
      {
        dimensionValues: [{ value: 'login' }],
        metricValues: [{ value: '3' }, { value: '3' }],
      },
      {
        dimensionValues: [{ value: 'apply_start' }],
        metricValues: [{ value: '1' }, { value: '2' }],
      },
    ],
  };

  assert.deepEqual(parseRealtimeReport(report), {
    activeUsers: 4,
    totalEvents: 5,
    rows: [
      { event: 'login', users: 3, events: 3 },
      { event: 'apply_start', users: 1, events: 2 },
    ],
  });
});

test('parseRealtimeReport handles event-only rows', () => {
  const report = {
    totals: [{ metricValues: [{ value: '7' }, { value: '40' }] }],
    rows: [
      {
        dimensionValues: [{ value: 'screen_view' }],
        metricValues: [{ value: '20' }],
      },
      {
        dimensionValues: [{ value: 'search' }],
        metricValues: [{ value: '5' }],
      },
    ],
  };

  assert.deepEqual(parseRealtimeReport(report), {
    activeUsers: 7,
    totalEvents: 40,
    rows: [
      { event: 'screen_view', users: null, events: 20 },
      { event: 'search', users: null, events: 5 },
    ],
  });
});

test('parseRealtimeReport tolerates empty or malformed reports', () => {
  assert.deepEqual(parseRealtimeReport(null), {
    activeUsers: 0,
    totalEvents: 0,
    rows: [],
  });
  assert.deepEqual(parseRealtimeReport({ rows: [{ metricValues: [] }] }), {
    activeUsers: 0,
    totalEvents: 0,
    rows: [],
  });
  assert.deepEqual(
    parseRealtimeReport({
      totals: [{ metricValues: [{ value: 'not-a-number' }, {}] }],
      rows: [
        {
          dimensionValues: [{ value: 'screen_view' }],
          metricValues: [{ value: 'x' }, { value: '4' }],
        },
      ],
    }),
    {
      activeUsers: 0,
      totalEvents: 0,
      rows: [{ event: 'screen_view', users: 0, events: 4 }],
    },
  );
});

test('quotaRemaining reads the project/hour bucket', () => {
  assert.equal(
    quotaRemaining({
      tokensPerProjectPerHour: { consumed: 1, remaining: 13999 },
    }),
    13999,
  );
  assert.equal(quotaRemaining(null), null);
  assert.equal(quotaRemaining({}), null);
});
