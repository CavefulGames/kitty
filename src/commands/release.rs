use structopt::StructOpt;

#[derive(Debug,StructOpt)]
pub struct ReleaseSubcommand{

}

impl ReleaseSubcommand{
	pub fn run(self) -> anyhow::Result<()> {
		Ok(())
	}
}
