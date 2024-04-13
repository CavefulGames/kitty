use structopt::StructOpt;
use wally_package_types::Command;

#[derive(Debug, StructOpt)]
pub struct InstallSubcommand {

}

impl InstallSubcommand {
	pub fn run(self) -> anyhow::Result<()> {
		// let cmd = Command{
		// 	sourcemap:
		// };
		println!("hi there");
		Ok(())
	}
}
