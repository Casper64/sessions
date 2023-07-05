# Sessions

An implementation of session for Vweb. Heavily inspired by [express-session](https://github.com/expressjs/session)

This module contains 2 options for storing data: in a database and in memory, but it
is possible to define your own store to use with other backends like redis
(see [Custom Stores](#implementing-your-own-store)).

## Usage

See [examples](examples/main.v).

### Create a session object

First we create a new `Session` instance in the main function and add it to our `App` struct, 
we will use the [MemoryStore](#memorystore) to store the data in memory.

```v
module main

import vweb
import sessions

const (
	secret = 'my-secret'
)

pub struct User {
	name string
	id   int
}

pub struct App {
	vweb.Context
pub mut:
	sessions &sessions.Session[User] [vweb_global]
}

fn main() {
    // create the Session object
	mut s := sessions.Session.create(sessions.MemoryStore[User]{}, secret: secret)

	mut app := &App{
		sessions: s
	}

	vweb.run(app, 8080)
}
```

### Loading sessions

You can load the current session with the `use` function.

**Example:**
```v ignore
pub fn (mut app App) before_request() {
    // load the session before any route is handled
    app.sessions.use()
}
```

Or load the sessions via middleware

**Example:**
```v ignore
pub struct App {
	vweb.Context
	middlewares map[string][]vweb.Middleware
pub mut:
	sessions &sessions.Session[User] [vweb_global]
}

fn main() {
	mut s := sessions.Session.create(sessions.MemoryStore[User]{}, secret: secret)

	mut app := &App{
		sessions: s
		middlewares: {
			'/': [s.use]
		}
	}

	vweb.run(app, 8080)
}
```

### Storing Data

Use `Session.save` to save data in the session store and associate it with the current session.

**Example:**
```v
pub fn (mut app App) index() vweb.Result {
	app.sessions.save(app.Context, User{
		name: 'casper'
		id: 3
	}) or { eprintln(err) }

	return app.html('User is set!')
}
```

### Retrieving Data

`Session.use` will add the session data in vweb's context. By default the key is `'user'`. 
We can easily retrieve the data from vweb's context.

**Example:**
```v
pub fn (mut app App) user() vweb.Result {
	user := app.get_value[User]('user') or { User{} }
	return app.json(user)
}
```

## Stores

There are 2 stores that you can use to store session data: 

### MemoryStore

Use the `MemoryStore` to store session data in RAM.

Pros
- Fast read and write speeds

Cons
- Every time the program needs to be restarted the session data is lost

**Example:**
```v ignore
sessions.Session.create(sessions.MemoryStore[User]{}, secret: 'my-secret')
```

### DatabaseStore

> **Note:** the DatabaseStore does not work yet, because of some generic orm issue in V see
> [#18788](https://github.com/vlang/v/issues/18788).

Use the `DatabaseStore` to store session data in a database.

Pros
- Persistent data when the program is restarted

Cons
- May have performance issues due to the frequent read and writes

**Example:**
```v ignore
import db.sqlite

db := sqlite.connect('sessions.db')!
mut s := sessions.session(sessions.DatabaseStore.create[User](db),
	secret: 'my-secret'
)
```

## Implementing your own store

It is possible to define your own Store e.g. to connect it to another service like redis.

If you store implements the `Store` interface you can use it.

```v ignore

pub interface Store[T] {
	all() []T
	get(sid string) ?T
mut:
	destroy(sid string)
	clear()
	set(sid string, val T)
}
```

### Methods

- `all() []T` should retrieve all session data
- `get(sid string) ?T` should retrieve the session data that belongs to session 
id `sid` if it exists.
- `destroy(sid string)` should destroy the data that belongs to session id `sid`
if it exists.
- `clear()` should clear all stored data
- `set(sid string, val T)` should set the session data that belogns to session id 
`sid` to `val`
