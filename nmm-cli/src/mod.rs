use http::Request;

trait RemoteMod {
    fn fetch(&self) -> Result<Mod, http::Error>;
}

struct Mod {
    name: String,
    description: String,
    version: String,
    author: String,
    id: String,

    provider_url: String,
}

struct Download {
    url: String,
}

impl RemoteMod for Mod {
    fn fetch(&self) -> Result<Mod, http::Error> {
        let request = Request::builder()
            .uri(&self.provider_url)
            .header("Accept", "Application/JSON")
            .body(());

        request.map(|res| Mod {
            name: "lol".into(),
            description: "lol".into(),
            version: "lol".into(),
            author: "lol".into(),
            id: "lol".into(),
            provider_url: "lol".into(),
        })
    }
}
