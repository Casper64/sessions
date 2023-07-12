module sessions

pub interface Store[T] {
mut:
	all() []T
	get(sid string) ?T
	destroy(sid string)
	clear()
	set(sid string, val T)
}
