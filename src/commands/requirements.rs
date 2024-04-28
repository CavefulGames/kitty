use structopt::StructOpt;
use crate::requirements;

#[derive(Debug,StructOpt)]
pub struct RequirementsSubcommand{

}

impl RequirementsSubcommand{
	pub fn run(self) -> anyhow::Result<()> {
		println!("Requirements: {:?}",requirements::REQUIREMENTS);
		println!("Missing requirements: {:?}",requirements::get_missing());
		Ok(())
	}
}
