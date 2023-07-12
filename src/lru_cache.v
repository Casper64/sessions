module sessions

// Simple LRU-cache
[heap]
struct Node[T] {
pub mut:
	key string
	val T

	prev &Node[T] = unsafe { nil }
	next &Node[T] = unsafe { nil }
}

struct LRUCache[T] {
	cap int
pub mut:
	cache map[string]&Node[T]

	left  &Node[T] = unsafe { nil }
	right &Node[T] = unsafe { nil }
}

fn (mut lru LRUCache[T]) remove(node &Node[T]) {
	mut prev, mut nxt := node.prev, node.next
	prev.next, nxt.prev = nxt, prev
}

fn (mut lru LRUCache[T]) insert(mut node Node[T]) {
	mut prev, mut nxt := lru.right.prev, lru.right

	nxt.prev = node
	prev.next = node

	node.next, node.prev = nxt, prev
}

pub fn (mut lru LRUCache[T]) get(key string) ?T {
	if mut v := lru.cache[key] {
		lru.remove(v)
		lru.insert(mut v)
		return v.val
	}
	return none
}

pub fn (mut lru LRUCache[T]) put(key string, value T) {
	if v := lru.cache[key] {
		lru.remove(v)
	}

	mut new_v := &Node[T]{
		key: key
		val: value
	}

	lru.cache[key] = new_v
	lru.insert(mut new_v)

	if lru.cache.len > lru.cap {
		least := lru.left.next
		lru.remove(least)
		lru.cache.delete(least.key)
	}
}

pub fn (mut lru LRUCache[T]) clear(key string) {
	if v := lru.cache[key] {
		lru.remove(v)
		lru.cache.delete(key)
	}
}

pub fn LRUCache.create[T](cap int) LRUCache[T] {
	mut cache := LRUCache[T]{
		cap: cap
		left: &Node[T]{}
		right: &Node[T]{}
	}
	cache.left.next = cache.right
	cache.right.prev = cache.left

	return cache
}
