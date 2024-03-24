use clap::{Parser, Subcommand};
use std::path::PathBuf;

mod providers;
mod r#mod;

// https://docs.rs/clap/latest/clap/_derive/index.html#arg-attributes
// https://docs.rs/clap/latest/clap/_derive/_tutorial/chapter_0/index.html

#[derive(Parser)]
#[command(version, about, long_about)]
struct Cli {
    name: Option<String>,

    #[arg(short, long, value_name = "FILE")]
    config: Option<PathBuf>,

    #[arg(short, long, action = clap::ArgAction::Count)]
    debug: u8,

    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    // The name of the provider.
    #[arg(short, long)]
    provider: i32,
}

#[derive(Subcommand)]
enum Commands {
    Fetch {
        provider: Option<String>,
        mod_id: Option<String>,
        file_id: Option<String>,
        expire: Option<String>,
        key: Option<String>,
    },

    Init
}

#[tokio::main]
async fn main() {

}
