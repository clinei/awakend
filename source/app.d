void main() {
	import vibe.core.core : lowerPrivileges;
	lowerPrivileges();

	auto client = new AwakensClient();

	import vibe.core.core : runEventLoop;
	runEventLoop();
}

class AwakensClient {
	static immutable(string) url = "wss://awakens.me:2096";

	import vibe.http.websockets : WebSocket;
	private WebSocket socket;

	string sid;

	this(bool autoConnect = true) {
		if (autoConnect) {
			this.connect();
		}
	}

	void connect() {
		import std.experimental.logger : log;
		import std.conv : to;

		import vibe.http.websockets : connectWebSocket;

		import vibe.inet.url : URL;
		this.socket = connectWebSocket(URL(this.url ~"/socket.io/?transport=websocket"));

		this.socket.send(`{"type": "requestJoin", {"nick": "SomethingBoo"}}`);

		import vibe.core.core : runTask;
		auto responseWriter = runTask((){
			while (this.socket.waitForData()) {
				auto txt = this.socket.receiveText();
				log(txt);
				import std.algorithm : countUntil;
				ptrdiff_t cutBegin = txt.countUntil("{");
				if (cutBegin >= 0) {
					txt = txt[cutBegin .. $];
					import vibe.data.json : parseJson;
					auto res = parseJson(txt);
					this.sid = res["sid"].to!string;
					//this.socket.send(`{"type": "msg", "message": {"message": "hello world"}`);
				}
			}
		});

		responseWriter.join();
	}

	void join() {
		this.socket.send(`{"type": "core", "message": {"command": "join", "data": {"nick": "tets"}}}`);
	}
}
