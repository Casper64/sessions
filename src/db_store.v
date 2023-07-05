module sessions

import orm

struct DbUser[T] {
pub mut:
	id   string [primary]
	data T
}

pub fn (u DbUser[T]) str() string {
	return 'User(session_id=${u.id}, data=${u.data})'
}

// DatabaseStore stores session data in a database
[heap]
pub struct DatabaseStore[T] {
	db orm.Connection
}

pub fn DatabaseStore.create[T](db orm.Connection) &DatabaseStore[T] {
	mut store := &DatabaseStore[T]{
		db: db
	}
	store.init() or { panic(err) }
	return store
}

pub fn (mut store DatabaseStore[T]) init() ! {
	sql store.db {
		create table DbUser[T]
	}!
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
		// record does not exist yet
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
		delete from DbUser[T] where id != ''
	} or {}
}
