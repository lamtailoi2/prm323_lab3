const FNV_OFFSET_BASIS = 0xcbf29ce484222325n;
const FNV_PRIME = 0x100000001b3n;
const MASK_64 = (1n << 64n) - 1n;

/**
 * The 16-hex-character FNV-1a 64 key used by the Flutter app
 * (`lib/core/utils/job_key.dart`). Both sides must produce the same value so
 * a listing keeps one Firestore document ID.
 */
export function jobKeyFor(jobId: string): string {
  let hash = FNV_OFFSET_BASIS;
  for (const byte of Buffer.from(jobId, 'utf8')) {
    hash ^= BigInt(byte);
    hash = (hash * FNV_PRIME) & MASK_64;
  }
  return hash.toString(16).padStart(16, '0');
}
