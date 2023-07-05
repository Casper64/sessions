module sessions

// MemoryStore stores session data in memory
[heap]
pub struct MemoryStore[T] {
mut:
	// TODO: implement via LRU cache
	data map[string]T
}

pub fn (store &MemoryStore[T]) all() []T {
	return store.data.values()
}

pub fn (store &MemoryStore[T]) get(sid string) ?T {
	if val := store.data[sid] {
		return val
	}
	return none
}

pub fn (mut store MemoryStore[T]) destroy(sid string) {
	store.data.delete(sid)
}

pub fn (mut store MemoryStore[T]) set(sid string, val T) {
	store.data[sid] = val
}

pub fn (mut store MemoryStore[T]) clear() {
	keys := store.data.keys()
	for key in keys {
		store.data.delete(key)
	}
}
