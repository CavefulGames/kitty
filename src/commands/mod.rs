mod install;
mod kit;
mod reload;

pub use install::InstallSubcommand;
pub use kit::KitSubcommand;
pub use reload::ReloadSubcommand;

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
            Subcommand::Reload(subcommand) => subcommand.run(),
        }
    }
}

#[derive(Debug, StructOpt)]
pub enum Subcommand {
    Install(InstallSubcommand),
	Kit(KitSubcommand),
    Reload(ReloadSubcommand),
}
