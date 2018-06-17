public class Tootle.DirectView : TimelineView {

    public DirectView () {
        base ("direct");
        notificator = new Notificator (get_stream ());
        notificator.status_added.connect ((ref status) => {
            if (settings.live_updates)
                on_status_added (ref status);
        });
    }
    
    public override string get_icon () {
        return "mail-send-symbolic";
    }
    
    public override string get_name () {
        return _("Direct Messages");
    }
    
    protected Soup.Message get_stream () {
        var url = "%s/api/v1/streaming/?stream=direct&access_token=%s".printf (accounts.formal.instance, accounts.formal.token);
        return new Soup.Message("GET", url);
    }

}
