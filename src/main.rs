use std::process::exit;

use structopt::StructOpt;

use libkitty::Args;

fn main() {
    let args = Args::from_args();

	if let Err(err) = args.run() {
        eprintln!("{:?}", err);
        exit(1);
    }
}
