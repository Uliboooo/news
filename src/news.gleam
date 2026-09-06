import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string

fn make_list(s) {
  string.replace(s, "[", "") |> string.replace("]", "") |> string.split(on: ",")
}

fn fetch_item(id: String) -> Result(#(String, String), String) {
  use req <- result.try(
    request.to("https://hacker-news.firebaseio.com/v0/item/" <> id <> ".json")
    |> result.map_error(fn(_) { "invalid request" }),
  )

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_) { "http error" }),
  )

  let decoder = {
    use title <- decode.field("title", decode.string)
    use url <- decode.field("url", decode.string)
    decode.success(#(title, url))
  }

  json.parse(from: resp.body, using: decoder)
  |> result.map_error(fn(_) { "json parse error" })
}

fn run(n: Int) -> Result(List(#(String, String)), String) {
  use req <- result.try(
    request.to("https://hacker-news.firebaseio.com/v0/topstories.json")
    |> result.map_error(fn(_) { "invalid request" }),
  )

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_) { "http error" }),
  )

  let ids =
    resp.body
    |> make_list()
    |> list.take(n)

  ids
  |> list.try_map(fetch_item)
}

fn fmt_tuple(s: #(String, String)) -> String {
  let #(f, b) = s
  "title: " <> f <> "\n" <> "url: " <> b
}

fn fmt_list_helper(acc: String, lst: List(String)) {
  case lst {
    [head, ..tail] -> fmt_list_helper(acc <> "\n\n" <> head, tail)
    [] -> acc
  }
}

fn fmt_list(lst: List(String)) {
  fmt_list_helper("", lst)
}

pub fn main() -> Nil {
  let n = 30
  let res = case run(n) {
    Ok(res) -> res |> list.map(fmt_tuple) |> fmt_list()
    Error(e) -> e
  }
  io.print(res)
  Nil
}
