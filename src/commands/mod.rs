mod install;
mod kit;
mod reload;
//mod test;
mod serve;
mod requirements;
mod list;
mod release;

pub use install::InstallSubcommand;
pub use kit::KitSubcommand;
pub use reload::ReloadSubcommand;
//pub use test::TestSubcommand;
pub use serve::ServeSubcommand;
pub use requirements::RequirementsSubcommand;
pub use list::ListSubcommand;

use structopt::StructOpt;

#[derive(Debug, StructOpt)]
pub enum Subcommand {
    Install(InstallSubcommand),
	Kit(KitSubcommand),
    Reload(ReloadSubcommand),
	//Test(TestSubcommand),
	Serve(ServeSubcommand),
	Requirements(RequirementsSubcommand),
	List(ListSubcommand),
}

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
			//Subcommand::Test(subcommand) => subcommand.run(),
			Subcommand::Serve(subcommand) => subcommand.run(),
			Subcommand::Requirements(subcommand) => subcommand.run(),
			Subcommand::List(subcommand) => subcommand.run(),
        }
    }
}
