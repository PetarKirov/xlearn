import vibe.d;

import userauth.userauth;
import userauth.services.persona;
import userauth.services.simple;

import std.range : retro, dropOne;

shared static this()
{
	setLogLevel(LogLevel.debugV);

	auto router = new URLRouter;

	auto auth = new UserAuth(router, "/");
	auth.register(new PersonaAuthService);

	router
		.get("*", serveStaticFiles("public/"))
		.get("/", &enter_page_with_auth!("dashboard", auth))
		.get("/login", &enter_page_with_auth!("login", auth))
		.get("/users/:email_base64", &profile!auth)
		.get("/course/:course_id/lesson/:lesson_id", &lesson!auth)
		.get("/about", &enter_page_with_auth!("about", auth))
		.get("/images", &enter_page_with_auth!("images", auth))
		.get("/contacts", &enter_page_with_auth!("contacts", auth));
		

	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1", "192.168.2.17" ];
	settings.errorPageHandler = &error!auth;

	settings.sessionStore = new MemorySessionStore;
	listenHTTP(settings, router);

	logInfo("Please open %-(http://%s/ or %)/ in your browser.",
		settings.bindAddresses.dropOne.retro);
}

void enter_page_with_auth(string page_name, alias auth)
	(HTTPServerRequest req, HTTPServerResponse res)
{
	string page_file_name = page_name;
	res.render!(page_name ~ ".dt", req, auth, page_file_name);
}

void lesson(alias auth)(HTTPServerRequest req, HTTPServerResponse res)
{
	auto course_id = req.params["course_id"];
	auto lesson_id = req.params["lesson_id"];

	const string page_file_name = "lesson";
	res.render!(page_file_name ~ ".dt", req, auth,
		page_file_name, course_id, lesson_id);
}

void error(alias auth)
	(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error)
{
	const string page_file_name = "error";
	res.render!(page_file_name ~ ".dt", req, auth,
		page_file_name, error);
}

void profile(alias auth)(HTTPServerRequest req, HTTPServerResponse res)
{
	import std.base64 : Base64;
	char[] user_name = cast(char[])Base64.decode(req.params["email_base64"]);

	bool is_authorized_profile_view = auth.getAuthInfo(req).authenticated &&
		auth.getAuthInfo(req).email == user_name;

	if (is_authorized_profile_view)
	{
		const string page_file_name = "profile_full";

		// TODO: Fill with other info for an authenticated user
		res.render!(page_file_name ~ ".dt", req, auth,
			page_file_name, user_name);
	}
	else
	{
		const string page_file_name = "profile_public";

		res.render!(page_file_name ~ ".dt", req, auth,
			page_file_name, user_name);
	}
}
