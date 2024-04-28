use structopt::StructOpt;

#[derive(Debug,StructOpt)]
pub struct ListSubcommand{

}

impl ListSubcommand{
	pub fn run(self) -> anyhow::Result<()> {
		Ok(())
	}
}
