use actix_web::{get, post, App, web, HttpResponse, HttpServer, Responder};
use std::env;
use anyhow::anyhow;
use structopt::StructOpt;

const DEFAULT_PORT:&str = "34875";

#[derive(Debug, StructOpt)]
pub struct ServeSubcommand {

}

#[get("/place/{place_name}")]
async fn place(path: web::Path<String>) -> impl Responder {
	let place_name = path.into_inner();
	HttpResponse::Ok().body("0")
}

#[post("/sound")]
async fn sound(data: String) -> impl Responder {
	HttpResponse::Ok().body(data)
}

impl ServeSubcommand {
	pub fn run(self) -> anyhow::Result<()> {
		let rt = actix_rt::Runtime::new().unwrap();
		let handle = rt.spawn(async {
			let port = env::var("KITTY_SERVER_PORT").unwrap_or(DEFAULT_PORT.to_string()).parse().expect("failed to parse the port");
			println!("server started address: {}",port);
			HttpServer::new(|| {
				App::new()
					.service(place)
					.service(sound)
			})
			.bind(("localhost", port))?
			.run()
			.await
		});
		let result = rt.block_on(handle).unwrap();
		println!("{:?}",result);
		match result {
			Ok(_) => Ok(()),
			Err(_) => Err(anyhow!("Server failed to start"))
		}
	}
}
