import crypto from 'crypto';

type RandomValuesBuffer = NodeJS.ArrayBufferView;

// Polyfill WebCrypto for Node.js environments before AWS SDK initializes
if (typeof globalThis.crypto === 'undefined' || typeof (globalThis.crypto as { getRandomValues?: unknown })?.getRandomValues !== 'function') {
  const existingCrypto = (crypto.webcrypto || {}) as object;

  Object.defineProperty(globalThis, 'crypto', {
    value: {
      ...existingCrypto,
      getRandomValues<T extends RandomValuesBuffer>(buffer: T): T {
        return crypto.randomFillSync(buffer as unknown as Uint8Array) as unknown as T;
      },
      randomUUID(): string | undefined {
        return typeof crypto.randomUUID === 'function' ? crypto.randomUUID() : undefined;
      },
    },
    writable: true,
    configurable: true,
  });
}
