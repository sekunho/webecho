use axum::{response::Html, routing, Router};

#[tokio::main]
async fn main() {
    // please dkm for unwraps
    let app = Router::new().route("/echo", routing::get(echo));
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn echo() -> Html<String> {
    match std::env::var("APP_ECHO_ME") {
        Ok(val) => Html(format!("<h1>{val}</h1>")),
        Err(_) => Html(format!("bruh")),
    }
}
