use structopt::StructOpt;
use dialoguer::{MultiSelect,theme::ColorfulTheme};

#[derive(Debug, StructOpt)]
pub struct KitSubcommand {

}

impl KitSubcommand {
	pub fn run(self) -> anyhow::Result<()> {
		let multiselected = &[
			"Input",
			"Animator",
			"Util",
			"Net",
		];
		let defaults = &[false, false, false, false];
		let selections = MultiSelect::with_theme(&ColorfulTheme::default())
			.with_prompt("Select kits to add")
			.items(&multiselected[..])
			.defaults(&defaults[..])
			.interact()
			.unwrap();

		if selections.is_empty() {
			println!("You did not select anything :(");
		} else {
			println!("You selected these things:");
			for selection in selections {
				println!("  {}", multiselected[selection]);
			}
		}
		Ok(())
	}
}
