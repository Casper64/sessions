module sessions

pub interface Store[T] {
	all() []T
	get(sid string) ?T
mut:
	destroy(sid string)
	clear()
	set(sid string, val T)
	// touch(sid string)
}
