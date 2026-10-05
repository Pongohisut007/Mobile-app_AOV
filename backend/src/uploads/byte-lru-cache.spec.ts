import { ByteLruCache } from './byte-lru-cache';

describe('ByteLruCache', () => {
  it('returns stored values and undefined for missing keys', () => {
    const cache = new ByteLruCache<string>(100);
    cache.set('a', 'A', 10);

    expect(cache.get('a')).toBe('A');
    expect(cache.get('missing')).toBeUndefined();
  });

  it('evicts the least recently used entries when over the byte limit', () => {
    const cache = new ByteLruCache<string>(30);
    cache.set('a', 'A', 10);
    cache.set('b', 'B', 10);
    cache.set('c', 'C', 10);
    // ใช้ a ล่าสุด b จึงกลายเป็นอันเก่าสุด
    cache.get('a');
    cache.set('d', 'D', 10);

    expect(cache.get('b')).toBeUndefined();
    expect(cache.get('a')).toBe('A');
    expect(cache.get('c')).toBe('C');
    expect(cache.get('d')).toBe('D');
  });

  it('skips values larger than the whole cache', () => {
    const cache = new ByteLruCache<string>(10);
    cache.set('a', 'A', 5);
    cache.set('huge', 'H', 11);

    expect(cache.get('huge')).toBeUndefined();
    expect(cache.get('a')).toBe('A');
  });

  it('replacing a key frees the bytes of the old value', () => {
    const cache = new ByteLruCache<string>(20);
    cache.set('a', 'A1', 15);
    cache.set('a', 'A2', 15);
    cache.set('b', 'B', 5);

    expect(cache.get('a')).toBe('A2');
    expect(cache.get('b')).toBe('B');
  });

  it('delete removes the entry and ignores unknown keys', () => {
    const cache = new ByteLruCache<string>(20);
    cache.set('a', 'A', 5);
    cache.delete('a');
    cache.delete('unknown');

    expect(cache.get('a')).toBeUndefined();
  });
});
