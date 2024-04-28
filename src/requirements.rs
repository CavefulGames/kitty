use std::process::Command;

pub const REQUIREMENTS: [&str; 3] = ["wally","rojo","wally-package-types"];

pub fn exist(executable_name: &str) -> bool {
    match Command::new(executable_name).args(&["--version"]).output() {
        Ok(_) => true,
        Err(_) => false,
    }
}

pub fn get_missing() -> Vec<String> {
	let mut missings: Vec<String> = Vec::new();
	for req in REQUIREMENTS {
		if !exist(req) {
			missings.push(req.to_string());
		}
	}
	missings
}

pub fn check() {
	let missings = get_missing();
	if missings.len()
}
