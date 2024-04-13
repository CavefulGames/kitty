mod install;

pub use install::InstallSubcommand;

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
        }
    }
}

#[derive(Debug, StructOpt)]
pub enum Subcommand {
    Install(InstallSubcommand),
}
