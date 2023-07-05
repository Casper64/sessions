module main

import vweb
import sessions
import os
import db.sqlite

const (
	secret = os.getenv('SESSION_SECRET')
)

pub struct User {
pub mut:
	authenticated bool
	name          string
	id            int
}

struct App {
	vweb.Context
	middlewares map[string][]vweb.Middleware
pub mut:
	sessions &sessions.Session[User] [vweb_global]
}

['/'; get]
pub fn (mut app App) index() vweb.Result {
	users := app.sessions.all()

	println(app.sessions)

	return $vweb.html()
}

['/'; post]
pub fn (mut app App) register_user(name string) vweb.Result {
	if name == '' {
		app.set_status(400, '')
		return app.text('"username" is required!')
	}

	app.sessions.save(app.Context, User{
		authenticated: true
		name: name
		id: 2
	}) or {
		eprintln(err)
		app.set_status(500, '')
		return app.text(err.msg())
	}

	return app.redirect('/user')
}

['/user']
pub fn (mut app App) user() vweb.Result {
	user := app.get_value[User]('user') or { User{} }
	if user.authenticated == false {
		app.set_status(401, '')
		return app.text('HTTP 401: unauthorized. You are nog logged in yet!')
	}

	return $vweb.html()
}

fn main() {
	db := sqlite.connect('sessions.db')!

	mut s := sessions.session(sessions.MemoryStore[User]{}, secret: secret)
	// mut s := sessions.session(sessions.DatabaseStore[User]{
		// db: db
	// },
	// 	secret: secret
	// )

	mut app := &App{
		sessions: s
		middlewares: {
			'/': [s.use]
			// '/user': [s.required]
		}
	}

	vweb.run_at(app, family: .ip, port: 8080)!
}
