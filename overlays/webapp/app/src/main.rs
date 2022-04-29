use actix_web::{get, App, HttpServer, Responder, HttpResponse};
// use actix_web::{Result as AwResult};
// use maud::{html, Markup};
use std::io;
use structopt::StructOpt;

#[derive(Debug, StructOpt)]
#[structopt(name = "WebApp", about = "Web Application using Maud")]
struct Opt {
    /// Port on which serve the web application
    #[structopt(short, long)]
    port: u16,
}


#[get("/")]
async fn index() -> impl Responder {
    HttpResponse::Ok().body("Hello web app world!")
}

// AwResult<Markup> {
//     Ok(html! {
//         html {
//             body {
//                 h1 { "Hello World! My name is Maud" }
//             }
//         }
//     })
// }

#[actix_web::main]
async fn main() -> io::Result<()> {
    let opts = Opt::from_args();
    println!("Starting server on port {:?}", opts.port);
    HttpServer::new(|| App::new().service(index))
        .bind(("127.0.0.1", opts.port))?
        .run()
        .await
}
