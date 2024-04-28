use structopt::StructOpt;
use wally_package_types::Command as WPT;
use std::process::Command;
use std::path::PathBuf;
use anyhow::anyhow;
use crate::localization;

#[derive(Debug, StructOpt)]
pub struct ReloadSubcommand {

}

impl ReloadSubcommand {
    pub fn run(self) -> anyhow::Result<()> {
        let result = Command::new("rojo")
            .arg("sourcemap")
            .arg("-o")
            .arg("sourcemap.json")
            .output();
		match result {
            Ok(_) => {
                println!("{}",localization::get_text("rojo-ok"));
				let result = Command::new("wally-package-types")
					.arg("--sourcemap")
					.arg("sourcemap.json")
					.arg("Packages")
					.output();
				// let sourcemap_path = PathBuf::from("sourcemap.json");
				// let packages_folder = PathBuf::from("Packages");
				// let wpt = WPT{
				//     sourcemap: sourcemap_path,
				//     packages_folder: packages_folder,
				// };
				// let result = wpt.run();
				match result {
					Ok(_) => {
						println!("{}",localization::get_text("wpt-ok"));
						Ok(())
					}
					Err(value) => {
						println!("{}: {}",localization::get_text("wpt-err"),value);
						Err(anyhow!("wally-package-types exited not successfully"))
					}
				}
            }
            Err(value) => {
                println!("{}: {}",localization::get_text("rojo-err"),value);
				return Err(anyhow!("rojo exited not successfully"))
            }
        }
    }
}
