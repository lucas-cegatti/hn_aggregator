# HnAggregator

This projects polls data from Hacker News's top stories api and stores the 50 most at :mnesia.

Here's a descriptions of the most import modules:

* `HnAggregator.DataPoller` A GenServer that periodically polls the data (every 5 minutes) and saves it to the data source. It has a backoff implemented where after 5 attempts it will emit a telemetry event and halts de periodic poll.
* `HnAggregator.Schema` A GenServer responsible to manage the data source and to save, select and update the given data.
* `HnAggregator.Model` a struct to map the data saved into an elixir component
* `HnAggregator.Public` public context used by the controller, this is to encapsulate logic that should be not be responsability of the controller and also to avoid the controller calling the Schema directly.


## Testing

Tests are build at `/test` folder and they do not use mocks, I chose to directly call the apis when testing to directly call the :httpc module and also test its behaviour. 

Mocks are quite simple to add, I would just change the HTTP library, to Testla, and use its mocking feature, I would also isolate the HTTP calls to a specific module.

To run the tests simply run:

```shell
mix test
```

## Endpoints

To get the list of top stories access `/api/top_stories` it will return a paginated list with 10 results and a `next_page` field with the offset to get the next page. When the last page is reached the field `next_page` will have the value `end_of_page`.

`next_page` can also be sent to the top_stories endpoint as a query parameter to fetch the next page, e.g., `http://localhost:4000/api/top_stories?next_page=$next_page`

The websocket is implemented and the channel to join is `hn:top_stories` every update to the data is broadcasted via Endpoint.broadcast!/3.

## Telemetry
Two telemetry events are executed:

* `data_poller.http_status.value` a counter for each http code returned by the HN endpoint
* `data_poller.poll_halted.total` a summary for when the polling of data is halted after max retries is reached.

## Running the application

This project was built using elixir `v1.14.2` and erlang `25.1.2` if you use asdf the .tools-versions file will help you to set those versions.

After installing both elixir and erlang run `mix deps.get` to fetch all dependencias and then start the app.

To start the app locally simply run `iex -S mix phx.server` server will respond in port 4000. After that you can acess the top stories endpoint via: `http://localhost:4000/api/top_stories`

## Building with docker

To build the image run `docker build -t hn_aggregator .` when it finishes run it with `docker run -e SECRET_KEY_BASE=$SECRET_KEY_BASE hn_aggregator`, do not forget to set the `SECRET_KEY_BASE` env var.