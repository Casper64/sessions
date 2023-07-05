module sessions

import orm

struct DbUser[T] {
pub mut:
	id   string [primary]
	data T
}

pub struct DatabaseStore[T] {
	db orm.Connection
}

pub fn (store &DatabaseStore[T]) all() []T {
	rows := sql store.db {
		select from DbUser[T]
	} or { []DbUser[T]{} }

	return rows.map(it.data)
}

pub fn (store &DatabaseStore[T]) get(sid string) ?T {
	rows := sql store.db {
		select from DbUser[T] where id == sid
	} or { []DbUser[T]{} }

	if rows.len == 0 {
		return none
	}
	return rows[0].data
}

pub fn (mut store DatabaseStore[T]) destroy(sid string) {
	sql store.db {
		delete from DbUser[T] where id == sid
	} or {}
}

pub fn (mut store DatabaseStore[T]) set(sid string, val T) {
	rows := sql store.db {
		select from DbUser[T] where id == sid
	} or { []DbUser[T]{} }

	mut user := DbUser[T]{
		id: sid
		data: val
	}

	if rows.len == 0 {
		// create record
		sql store.db {
			insert user into DbUser[T]
		} or { eprintln(err) }
	} else {
		// TODO: use update doesn't work?
		sql store.db {
			delete from DbUser[T] where id == sid
			insert user into DbUser[T]
		} or { eprintln(err) }
	}
}

pub fn (mut store DatabaseStore[T]) clear() {
	// TODO: generic structs don't work with deleting all
	sql store.db {
		delete from DbUser[T] where id != '2'
	} or {}
}
