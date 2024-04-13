mod install;
mod kit;

pub use install::InstallSubcommand;
pub use kit::KitSubcommand;

use structopt::StructOpt;

#[derive(Debug, StructOpt)]
#[structopt(about = env!("CARGO_PKG_DESCRIPTION"))]
pub struct Args {
    #[structopt(subcommand)]
    pub subcommand: Subcommand,
}

impl Args {
    pub fn run(self) -> anyhow::Result<()> {
        match self.subcommand {
            Subcommand::Install(subcommand) => subcommand.run(),
			Subcommand::Kit(subcommand) => subcommand.run(),
        }
    }
}

#[derive(Debug, StructOpt)]
pub enum Subcommand {
    Install(InstallSubcommand),
	Kit(KitSubcommand),
}
