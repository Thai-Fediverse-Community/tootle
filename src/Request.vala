using Soup;
using Gee;

public class Tootle.Request : Soup.Message {

	public string url { set; get; }
	Network.SuccessCallback? cb;
	Network.ErrorCallback? error_cb;
	HashMap<string, string>? pars;
	weak InstanceAccount? account;
	bool needs_token = false;

	weak Gtk.Widget? ctx;
	bool has_ctx = false;

	public Request.GET (string url) {
		Object (method: "GET", url: url);
	}
	public Request.POST (string url) {
		Object (method: "POST", url: url);
	}
	public Request.DELETE (string url) {
		Object (method: "DELETE", url: url);
	}

	public Request with_ctx (Gtk.Widget ctx) {
		this.has_ctx = true;
		this.ctx = ctx;
		this.ctx.destroy.connect (() => {
			network.cancel (this);
			this.ctx = null;
		});
		return this;
	}

	public Request then (owned Network.SuccessCallback cb) {
		this.cb = (s, m) => {
			Idle.add (() => {
				cb (s, m);
				return false;
			});
		};
		return this;
	}

	public Request on_error (owned Network.ErrorCallback cb) {
		this.error_cb = (owned) cb;
		return this;
	}

	public Request with_account (InstanceAccount? account = null) {
		this.needs_token = true;
		if (account != null)
			this.account = account;
		return this;
	}

	public Request with_param (string name, string val) {
		if (pars == null)
			pars = new HashMap<string, string> ();
		pars[name] = val;
		return this;
	}

	public Request exec () {
		var parameters = "";
		if (pars != null) {
			parameters = "?";
			var parameters_counter = 0;
			pars.@foreach (entry => {
				parameters_counter++;
				var key = (string) entry.key;
				var val = (string) entry.value;
				parameters += @"$key=$val";

				if (parameters_counter < pars.size)
					parameters += "&";

				return true;
			});
		}

		if (needs_token) {
			if (account == null) {
				warning (@"No account was specified or found for $method: $url$parameters");
				return this;
			}
			request_headers.append ("Authorization", @"Bearer $(account.access_token)");
		}

		if (!("://" in url)) {
			url = account.instance + url;
		}

		this.uri = new URI (url + "" + parameters);

		url = uri.to_string (false);
		debug (@"$method: $url");

		network.queue (this, (owned) cb, (owned) error_cb);
		return this;
	}

}
