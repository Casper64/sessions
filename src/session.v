module sessions

import vweb
import rand
import net.http
import crypto.sha256
import crypto.hmac
import encoding.base64

fn sign(value string, secret []u8) string {
	b := hmac.new(secret, value.bytes(), sha256.sum, sha256.block_size)
	s := base64.url_encode(b)

	return '${value}.${s}'
}

fn unsign(value string, input string, secret []u8) bool {
	expected := sign(value, secret)

	// TODO: use compare function that always runs in the same time
	return input.len == expected.len && input == expected
}

[heap]
pub struct Session[T] {
	secret []u8
mut:
	store Store[T]
pub:
	cookie_name string
	user_key    string
}

// middleware stuff:
fn (mut s Session[T]) create_session(mut ctx vweb.Context) string {
	sid := rand.hex(24)

	// cookie value = UID + . + hmac
	signed := sign(sid, s.secret)

	ctx.set_cookie(http.Cookie{
		name: s.cookie_name
		value: signed
	})
	ctx.set_value('session_id', sid)

	s.store.set(sid, T{})
	return sid
}

pub fn (s &Session[T]) validate_session(ctx vweb.Context) (string, bool) {
	cookie := ctx.get_cookie(s.cookie_name) or { return '', false }

	splitted := cookie.split('.')
	if splitted.len != 2 {
		return '', false
	}
	return splitted[0], unsign(splitted[0], cookie, s.secret)
}

pub fn (mut s Session[T]) use(mut ctx vweb.Context) bool {
	// validate session id
	sid, valid := s.validate_session(ctx)

	if !valid {
		// invalid session id
		s.create_session(mut ctx)
		return true
	}

	// valid session id
	ctx.set_value('session_id', sid)

	if val := s.store.get(sid) {
		// session id exists in store
		ctx.set_value(s.user_key, val)
		return true
	}

	// session id doesn't exist in store
	s.create_session(mut ctx)
	return true
}

// Util:

pub fn (s &Session[T]) get_session_id(ctx vweb.Context) ?string {
	if sid := ctx.get_value[string]('session_id') {
		return sid
	}

	cookie := ctx.get_cookie(s.cookie_name) or { return none }
	a := cookie.split('.')
	return a[0]
}

pub fn (s &Session[T]) logout(mut ctx vweb.Context) {
	ctx.set_cookie(http.Cookie{
		name: s.cookie_name
		value: ''
		max_age: -1
	})
	ctx.set_value('session_id', '')
}

// Store implementations:

// all retrieves all session data
pub fn (s &Session[T]) all() []T {
	return s.store.all()
}

// get the current session data
pub fn (s &Session[T]) get(ctx vweb.Context) ?T {
	sid := s.get_session_id(ctx)?
	return s.store.get(sid)
}

// destroy the current session data
pub fn (mut s Session[T]) destroy(ctx vweb.Context) {
	sid := s.get_session_id(ctx) or { return }
	s.store.destroy(sid)
}

// save puts `val` as new session data for the current session
pub fn (mut s Session[T]) save(ctx vweb.Context, val T) ! {
	mut sid := s.get_session_id(ctx) or { '' }
	if sid == '' {
		sid = ctx.get_value[string]('session_id') or { return error('Session id does not exist!') }
	}

	s.store.set(sid, val)
}

[params]
pub struct SessionParams {
	secret      string [required]
	cookie_name string = 'sid'
	// which key to use in `vweb.Context.get_value`
	user_key string = 'user'
}

// session creates a new Session instance
pub fn Session.create[T](store Store[T], params SessionParams) &Session[T] {
	return &Session[T]{
		store: store
		secret: params.secret.bytes()
		cookie_name: params.cookie_name
		user_key: params.user_key
	}
}
