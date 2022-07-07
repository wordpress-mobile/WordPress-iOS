# WordPressMocks

Network mocking for testing the WordPress mobile apps based on [WireMock](https://wiremock.org/)

## Usage

To start the WireMock server as a standalone process, you can run it with this command:

```
./scripts/start.sh 8282
```

Here `8282` is the port to run the server on. It can now be accessed from `http://localhost:8282`.

## Creating a mock file

The JSON files used by WireMock to handle requests and are located in `src/main/assets`. To generate one of these files
you're first going to want to set up [Charles Proxy](https://www.charlesproxy.com/) (or similar) to work with your iOS Simulator.

Here's an example of what a mock might look like:

```json
{
    "request": {
        "urlPattern": "/rest/v1.1/me/",
        "method": "GET"
    },
    "response": {
        "status": 200,
        "jsonBody": {
            // Your response here...
        },
        "headers": {
            "Content-Type": "application/json",
            "Connection": "keep-alive",
            "Cache-Control": "no-cache, must-revalidate, max-age=0"
        }
    }
}
```

These files are used to match network requests while the tests are being run. For more on request matching with
WireMock check out [their documentation](http://wiremock.org/docs/request-matching/).
