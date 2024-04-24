use structopt::StructOpt;
use wally_package_types::Command as WPT;
use std::process::Command;
use std::path::PathBuf;

#[derive(Debug, StructOpt)]
pub struct ReloadSubcommand {

}

impl ReloadSubcommand {
    pub fn run(self) -> anyhow::Result<()> {
        let this_name = "rojo";
        Command::new("rojo")
            .arg("sourcemap")
            .arg("-o")
            .arg("sourcemap.json")
            .spawn()
            .expect("Failed to run rojo command");
        let sourcemap_path = PathBuf::from("sourcemap.json");
        let packages_folder = PathBuf::from("Packages");
        let wpt = WPT{
            sourcemap: sourcemap_path,
            packages_folder: packages_folder,
        };
        let result = wpt.run();
        match result{
            Ok(_) => {
                println!("{}","Successfully completed");
            }
            Err(value) => {
                println!("wally-package-types warning: {}",value)
            }
        }
        Ok(())
    }
}
