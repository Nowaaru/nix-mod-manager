struct Provider {
    name: String,
}


impl Provider {
    pub fn new(provider_name: String) -> Provider {
        Provider {
            name: provider_name,
        }
    }
}
