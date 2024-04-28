use structopt::StructOpt;
use std::io::BufReader;
use std::fs::File;
use std::thread::sleep;
use std::time::Duration;
use ambisonic::{rodio::{self, Source}, AmbisonicBuilder};

#[derive(Debug, StructOpt)]
pub struct TestSubcommand {

}

impl TestSubcommand {
    pub fn run(self) -> anyhow::Result<()> {
		let scene = AmbisonicBuilder::default().build();

		let file = File::open("test/sample.wav").unwrap();
		let source = rodio::Decoder::new(BufReader::new(file)).unwrap().convert_samples();

		let repeated_source = source.repeat_infinite();
		let mut sound = scene.play_at(repeated_source, [50.0, 1.0, 0.0]);

		// move sound from right to left
		sound.set_velocity([-10.0, 0.0, 0.0]);
		for i in 0..1000 {
			sound.adjust_position([50.0 - i as f32 / 10.0, 1.0, 0.0]);
			sleep(Duration::from_millis(10));
		}
		sound.set_velocity([0.0, 0.0, 0.0]);
		Ok(())
	}
}
