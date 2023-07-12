module sessions

// MemoryStore stores session data in memory
[heap]
pub struct MemoryStore[T] {
mut:
	// TODO: implement via LRU cache
	lru LRUCache[T]
}

pub fn (store &MemoryStore[T]) all() []T {
	return store.lru.cache.values().map(it.val)
}

pub fn (mut store MemoryStore[T]) get(sid string) ?T {
	return store.lru.get(sid)
}

pub fn (mut store MemoryStore[T]) destroy(sid string) {
	if v := store.lru.cache[sid] {
		store.lru.remove(v)
		store.lru.cache.delete(sid)
	}
}

pub fn (mut store MemoryStore[T]) set(sid string, val T) {
	store.lru.put(sid, val)
}

pub fn (mut store MemoryStore[T]) clear() {
	keys := store.lru.cache.keys()
	for key in keys {
		store.destroy(key)
	}
}

pub fn MemoryStore.create[T](capacity int) &MemoryStore[T] {
	mut store := &MemoryStore[T]{
		lru: LRUCache.create[T](capacity)
	}
	return store
}
