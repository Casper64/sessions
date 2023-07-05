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
	middlewares map[string][]vweb.Middleware
pub mut:
	sessions &sessions.Session[User] [vweb_global]
}

pub fn (mut app App) index() vweb.Result {
	sid := app.get_value[string]('session_id') or { '' }
	println('current session: ${sid}')

	app.sessions.save(app.Context, User{
		name: 'casper'
		id: 3
	}) or { eprintln(err) }

	return app.html('User is set!')
}

pub fn (mut app App) user() vweb.Result {
	user := app.get_value[User]('user') or { User{} }
	return app.json(user)
}

pub fn (mut app App) logout() vweb.Result {
	app.sessions.logout(mut app.Context)
	return app.html('logged out')
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
